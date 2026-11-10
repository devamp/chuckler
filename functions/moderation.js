// Moderation: reports, blocks and the word filter. App Store guideline 1.2
// asks for a way to filter objectionable content, to report it (and act on
// reports), and to block abusive users. See docs/data-model.md.

const {FieldValue} = require("firebase-admin/firestore");
// every category: the server treats any listed word as a reason to hide
// reported content quickly
const WORDS = new Set(Object.values(require("./wordlist.json").categories)
    .flatMap((c) => c.words));

// distinct reporters that hide something without a review
const HIDE_AT = 3;

const SWAPS = {"0": "o", "1": "i", "3": "e", "4": "a", "5": "s", "@": "a",
  "$": "s"};

/**
 * Lowercases and undoes common letter swaps, keeping word breaks.
 * @param {string} text
 * @return {Array<string>} the words
 */
function words(text) {
  const swapped = String(text || "").toLowerCase()
      .replace(/[01345@$]/g, (c) => SWAPS[c]);
  return swapped.split(/[^a-z]+/).filter(Boolean);
}

/**
 * Whether text holds a word from the list: whole words, with a trailing
 * s/es/ed/ing allowed, so "class" or "Scunthorpe" don't match. The app's
 * containsBlockedWords is the twin.
 * @param {string} text
 * @return {boolean}
 */
function containsBlockedWords(text) {
  const list = words(text);
  // words split by spaces, e.g. "k y s", also checked joined up
  const joined = list.filter((w) => w.length === 1).join("");
  for (const w of [...list, joined]) {
    if (!w) continue;
    if (WORDS.has(w)) return true;
    for (const end of ["s", "es", "ed", "ing"]) {
      if (w.endsWith(end) && WORDS.has(w.slice(0, -end.length))) return true;
    }
  }
  return false;
}

/**
 * The moderation doc id for a report's target.
 * @param {object} report
 * @return {string}
 */
function targetKey(report) {
  return `${report.targetType}_${report.targetId}`;
}

/**
 * Whether a target should be hidden now: enough distinct reporters, or one
 * report on text with a listed word.
 * @param {number} reporters distinct reporters so far
 * @param {boolean} flagged the text has a listed word
 * @return {boolean}
 */
function shouldHide(reporters, flagged) {
  return reporters >= HIDE_AT || (flagged && reporters >= 1);
}

/**
 * Adds matchup ids to a user's blockedContent, which keeps them out of the
 * user's Home queue. Only the last 200 are kept (matchups last a day).
 * @param {object} db
 * @param {string} uid
 * @param {Array<string>} ids
 */
async function addBlockedMatchups(db, uid, ids) {
  if (ids.length === 0) return;
  const ref = db.collection("Users").doc(uid)
      .collection("Private").doc("blockedContent");
  await db.runTransaction(async (tx) => {
    const now = (await tx.get(ref)).data()?.matchupIds || [];
    const all = [...new Set([...now, ...ids])].slice(-200);
    tx.set(ref, {matchupIds: all}, {merge: true});
  });
}

/**
 * After a new matchup: anyone who blocked one of its authors gets it added
 * to their blockedContent. Nothing goes on the matchup itself, so it stays
 * anonymous.
 * @param {object} db
 * @param {string} matchupId
 * @param {Array<string>} authorUids
 */
async function noteBlockedMatchup(db, matchupId, authorUids) {
  const blockers = new Set();
  for (const uid of authorUids.filter(Boolean)) {
    const snap = await db.collectionGroup("Blocked")
        .where("uid", "==", uid).get();
    for (const d of snap.docs) blockers.add(d.ref.parent.parent.id);
  }
  for (const b of blockers) await addBlockedMatchups(db, b, [matchupId]);
}

/**
 * When `uid` blocks `other`: they stop being friends, requests between
 * them go, and other's open matchups leave uid's queue.
 * @param {object} db
 * @param {string} uid
 * @param {string} other
 * @param {string} today the prompt day
 * @param {string} yesterday
 * @return {Promise<number>} matchups hidden
 */
async function applyBlock(db, uid, other, today, yesterday) {
  const users = db.collection("Users");
  const batch = db.batch();
  batch.delete(users.doc(uid).collection("Friends").doc(other));
  batch.delete(users.doc(other).collection("Friends").doc(uid));
  batch.delete(users.doc(uid).collection("FriendRequests").doc(other));
  batch.delete(users.doc(other).collection("FriendRequests").doc(uid));
  await batch.commit();

  const posts = await db.collection("Posts").where("uid", "==", other)
      .where("promptDateId", "in", [today, yesterday]).get();
  const ids = [];
  for (const p of posts.docs) {
    const ms = await db.collection("MatchUps")
        .where("postIds", "array-contains", p.id).get();
    ms.docs.forEach((m) => ids.push(m.id));
  }
  await addBlockedMatchups(db, uid, ids);
  return ids.length;
}

/**
 * The text a report is about, for the word check; "" if it's gone.
 * @param {object} db
 * @param {object} r the report
 * @return {Promise<string>}
 */
async function reportedText(db, r) {
  if (r.targetType === "answer") {
    return (await db.collection("Posts").doc(r.targetId).get())
        .data()?.answer || "";
  }
  if (r.targetType === "prompt") {
    const p = (await db.collection("FriendPrompts").doc(r.targetId).get())
        .data() || {};
    return `${p.before || ""} ${p.after || ""}`;
  }
  if (r.targetType === "comment" && r.postId) {
    const pages = await db.collection("Posts").doc(r.postId)
        .collection("CommentPages").get();
    for (const page of pages.docs) {
      const c = (page.data().comments || {})[r.targetId];
      if (c) return c.text || "";
    }
  }
  if (r.targetType === "user") {
    return (await db.collection("Users").doc(r.targetId).get())
        .data()?.username || "";
  }
  return "";
}

/**
 * Hides reported content: an answer and its matchups, a comment (deleted),
 * or a friend prompt. Users aren't hidden automatically; review them.
 * @param {object} db
 * @param {object} r the report
 * @return {Promise<boolean>} whether anything was hidden
 */
async function hideTarget(db, r) {
  if (r.targetType === "answer") {
    await db.collection("Posts").doc(r.targetId).update({status: "hidden"});
    const ms = await db.collection("MatchUps")
        .where("postIds", "array-contains", r.targetId).get();
    for (const m of ms.docs) await m.ref.update({status: "hidden"});
    return true;
  }
  if (r.targetType === "prompt") {
    await db.collection("FriendPrompts").doc(r.targetId)
        .update({status: "hidden"});
    return true;
  }
  if (r.targetType === "comment" && r.postId) {
    const pages = await db.collection("Posts").doc(r.postId)
        .collection("CommentPages").get();
    for (const page of pages.docs) {
      if ((page.data().comments || {})[r.targetId]) {
        await page.ref.update(
            {[`comments.${r.targetId}`]: FieldValue.delete()});
        return true;
      }
    }
  }
  return false;
}

/**
 * Records a report on its target's Moderation doc (each reporter counts
 * once) and hides the target once shouldHide says so.
 * @param {object} db
 * @param {object} r the report
 * @return {Promise<object>} {reporters, flagged, hidden}
 */
async function handleReport(db, r) {
  const ref = db.collection("Moderation").doc(targetKey(r));
  const text = await reportedText(db, r);
  const flagged = containsBlockedWords(text);
  const state = await db.runTransaction(async (tx) => {
    const m = (await tx.get(ref)).data() || {};
    const reporters = [...new Set([...(m.reporters || []), r.reporter])];
    const hide = m.status !== "hidden" && shouldHide(reporters.length, flagged);
    tx.set(ref, {
      targetType: r.targetType, targetId: r.targetId,
      ...(r.postId ? {postId: r.postId} : {}),
      ...(r.matchupId ? {matchupId: r.matchupId} : {}),
      reporters, count: reporters.length, flagged,
      reasons: FieldValue.arrayUnion(r.reason || "other"),
      status: hide ? "hidden" : (m.status || "open"),
      ...(m.firstAt ? {} : {firstAt: FieldValue.serverTimestamp()}),
      lastAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    return {reporters: reporters.length, hide};
  });
  let hidden = false;
  if (state.hide) hidden = await hideTarget(db, r);
  return {reporters: state.reporters, flagged, hidden};
}

module.exports = {
  containsBlockedWords, shouldHide, targetKey, addBlockedMatchups,
  noteBlockedMatchup, applyBlock, handleReport, HIDE_AT,
};
