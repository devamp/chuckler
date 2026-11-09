// Daily results: once a prompt day ends, each answer's final stats go into
// its author's History entry (`final`), and each author gets one results
// notification. Run by the dailyResults schedule, or in the emulator by
// `npm --prefix functions run finish-day [dayId]`.

const {FieldValue} = require("firebase-admin/firestore");
const {notificationRef, notification, clip} = require("./profile");

/**
 * An answer's final stats from its post's counts. The win rate is
 * wins ÷ (wins + dislikes), or null with neither.
 * @param {object} post
 * @return {object}
 */
function finalStats(post) {
  const c = post.counts || {};
  const wins = c.wins || 0;
  const dislikes = c.dislikes || 0;
  const judged = wins + dislikes;
  return {
    wins, dislikes,
    votes: c.votes || 0,
    matchups: c.matchups || 0,
    comments: c.comments || post.commentCount || 0,
    winRate: judged ? Math.round(wins / judged * 100) / 100 : null,
  };
}

/**
 * "Nov 8" for a day id.
 * @param {string} dayId
 * @return {string}
 */
function shortDate(dayId) {
  return new Date(`${dayId}T00:00:00Z`).toLocaleDateString("en-US",
      {month: "short", day: "numeric", timeZone: "UTC"});
}

/**
 * The results notification text for one author's answers that day.
 * @param {string} dayId
 * @param {Array<{post: object, final: object}>} answers
 * @return {string}
 */
function resultsText(dayId, answers) {
  const n = answers.length;
  const wins = answers.reduce((t, a) => t + a.final.wins, 0);
  const votes = answers.reduce((t, a) => t + a.final.votes, 0);
  const what = `Your ${n === 1 ? "answer" : `${n} answers`} from ` +
      shortDate(dayId);
  if (votes === 0) return `${what} didn't get any votes.`;
  const best = answers.reduce((b, a) => a.final.wins > b.final.wins ? a : b);
  const won = `${what} won ${wins} of ${votes} ` +
      `${votes === 1 ? "vote" : "votes"}.`;
  if (best.final.wins === 0) return won;
  return `${won} Best: "${clip(best.post.answer)}" ` +
      `(${best.final.wins} ${best.final.wins === 1 ? "win" : "wins"})`;
}

/**
 * Finishes a prompt day. Skips a day already finished unless `force`.
 * @param {object} db
 * @param {string} dayId yyyy-MM-dd
 * @param {{force: boolean}} options
 * @return {Promise<object>} {answers, authors} or {skipped: true}
 */
async function finishDay(db, dayId, {force = false} = {}) {
  const dayRef = db.collection("PromptDays").doc(dayId);
  const day = await dayRef.get();
  if (!force && day.exists && day.data().resultsAt) return {skipped: true};

  const posts = await db.collection("Posts")
      .where("promptDateId", "==", dayId).get();
  const byAuthor = new Map();
  for (const doc of posts.docs) {
    const post = doc.data();
    if (!post.uid || !post.promptId) continue;
    if (!byAuthor.has(post.uid)) byAuthor.set(post.uid, []);
    byAuthor.get(post.uid).push({id: doc.id, post, final: finalStats(post)});
  }

  const writer = db.bulkWriter();
  for (const [uid, answers] of byAuthor) {
    const entries = {};
    for (const a of answers) {
      const p = a.post;
      // the whole entry, so an answer missing from History is filled in
      entries[`${dayId}_${p.promptId}`] = {
        postId: a.id, promptDateId: dayId, promptId: p.promptId,
        before: p.before || "", after: p.after || "", answer: p.answer || "",
        ...(p.date ? {at: p.date} : {}),
        final: a.final,
      };
    }
    writer.set(db.collection("Users").doc(uid)
        .collection("History").doc(dayId.substring(0, 7)),
    {answers: entries}, {merge: true});
    if (!force || !(day.exists && day.data().resultsAt)) {
      writer.set(notificationRef(db, uid), notification("results",
          resultsText(dayId, answers), {dayId}));
    }
  }
  writer.set(dayRef, {resultsAt: FieldValue.serverTimestamp()},
      {merge: true});
  await writer.close();
  return {answers: posts.size, authors: byAuthor.size};
}

module.exports = {finishDay, finalStats, resultsText, shortDate};
