const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {
  onDocumentCreated, onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {isDayId, markStreakDay} = require("./promptDay");
initializeApp();
const db = getFirestore();


// Matchups pair two answers to the same prompt for voting. They carry no
// uids or usernames, so vote cards are anonymous until you vote: then
// Authors/names (readable only by voters) shows who wrote each answer.
// Private/owners keeps the uids for the server. See docs/data-model.md.

/**
 * One side of a new matchup.
 * @param {string} postId
 * @param {object} post
 * @return {object}
 */
function matchupAnswer(postId, post) {
  return {postId, answer: post.answer || "", wins: 0, dislikes: 0,
    commentCount: post.commentCount || 0, preview: post.preview || []};
}

// createMatchup pairs a new post with the oldest unmatched post for the same
// prompt, or marks it unmatched to wait for the next one. It runs in a
// transaction, so two posts created together can't claim the same partner.
exports.createMatchup = onDocumentCreated("Posts/{postId}", async (event) => {
  const postId = event.params.postId;
  const postRef = event.data.ref;
  try {
    await db.runTransaction(async (tx) => {
      const post = (await tx.get(postRef)).data();
      // already handled (a retried event)
      if (!post || post.matched !== undefined) return;
      const {promptId, promptDateId} = post;
      if (!promptId || !promptDateId) return;

      const waiting = await tx.get(db.collection("Posts")
          .where("promptId", "==", promptId)
          .where("promptDateId", "==", promptDateId)
          .where("matched", "==", false)
          .orderBy("date", "asc")
          .limit(1));
      const other = waiting.docs.find((d) => d.id !== postId);
      if (!other) {
        tx.update(postRef, {matched: false});
        return;
      }
      const prompt = (await tx.get(db.doc(
          `PromptDays/${promptDateId}/Prompts/${promptId}`))).data() || {};
      const otherPost = other.data();
      // the authors' photos, for the names shown after someone votes
      const [otherUser, user] = await Promise.all([otherPost.uid, post.uid]
          .map((uid) => tx.get(db.collection("Users").doc(uid))));

      const matchupRef = db.collection("MatchUps").doc();
      // the waiting post goes on top, the new one below
      tx.set(matchupRef, {
        promptDateId, promptId,
        before: prompt.before ?? post.before ?? "",
        after: prompt.after ?? post.after ?? "",
        segment: prompt.location || "global",
        createdAt: FieldValue.serverTimestamp(),
        status: "active",
        postIds: [other.id, postId],
        answers: [matchupAnswer(other.id, otherPost),
          matchupAnswer(postId, post)],
      });
      tx.set(matchupRef.collection("Private").doc("owners"),
          {uids: [otherPost.uid, post.uid]});
      // who wrote each answer, readable only by people who voted on it
      tx.set(matchupRef.collection("Authors").doc("names"), {answers: [
        {username: otherPost.username || "",
          photoUrl: otherUser.data()?.profileImage || ""},
        {username: post.username || "",
          photoUrl: user.data()?.profileImage || ""},
      ]});
      for (const ref of [other.ref, postRef]) {
        tx.update(ref, {
          "matched": true,
          "counts.matchups": FieldValue.increment(1),
        });
      }
    });
  } catch (e) {
    console.log(`createMatchup: ${postId}: ${e}`);
  }
});

// onVoteCreated counts a vote on its matchup and on the two answers. A win
// adds to the picked answer's wins; a downvote to its dislikes on the
// matchup (the post's counts.dislikes was already added by the voter's
// batch, next to their Dislikes doc). Until ranking checkpoints exist, the
// posts' votes and wins are kept here too, so authors see their stats.
exports.onVoteCreated = onDocumentCreated("Votes/{voteId}", async (event) => {
  const vote = event.data.data();
  const {matchupId, card, type} = vote;
  if (!matchupId || (card !== 0 && card !== 1) ||
      (type !== "win" && type !== "dislike")) {
    console.log(`onVoteCreated: skipping malformed ${event.params.voteId}`);
    return;
  }
  const matchupRef = db.collection("MatchUps").doc(matchupId);
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(matchupRef);
      if (!snap.exists) return;
      const answers = snap.data().answers.map((a) => ({...a}));
      const key = type === "win" ? "wins" : "dislikes";
      answers[card][key] = (answers[card][key] || 0) + 1;
      tx.update(matchupRef, {answers});
      answers.forEach((a, i) => {
        const update = {"counts.votes": FieldValue.increment(1)};
        if (type === "win" && i === card) {
          update["counts.wins"] = FieldValue.increment(1);
        }
        tx.update(db.collection("Posts").doc(a.postId), update);
      });
    });
  } catch (e) {
    console.log(`onVoteCreated: ${event.params.voteId}: ${e}`);
  }
});

// How many of an answer's latest comments ride along on the post and its
// matchups, so the preview after voting costs no reads.
const PREVIEW_SIZE = 2;

// onCommentPageWritten keeps an answer's comment count and preview on the
// post and on the active matchups it's in, whenever a comment is added to
// or removed from one of its CommentPages.
exports.onCommentPageWritten = onDocumentWritten(
    "Posts/{postId}/CommentPages/{page}", async (event) => {
      const postId = event.params.postId;
      const before = event.data.before.data()?.comments || {};
      const after = event.data.after.data()?.comments || {};
      const delta = Object.keys(after).length - Object.keys(before).length;
      if (delta === 0) return;
      try {
        const postRef = db.collection("Posts").doc(postId);
        const pages = await postRef.collection("CommentPages").get();
        const all = [];
        pages.forEach((p) => {
          for (const c of Object.values(p.data().comments || {})) all.push(c);
        });
        all.sort((a, b) => a.at.toMillis() - b.at.toMillis());
        const preview = all.slice(-PREVIEW_SIZE).map((c) => ({
          username: c.username || "", text: c.text || "",
        }));
        const commentCount = all.length;

        await postRef.update(
            {commentCount, "counts.comments": commentCount, preview});
        const matchups = await db.collection("MatchUps")
            .where("postIds", "array-contains", postId)
            .where("status", "==", "active").get();
        for (const m of matchups.docs) {
          await db.runTransaction(async (tx) => {
            const snap = await tx.get(m.ref);
            const answers = snap.data().answers.map((a) =>
              a.postId === postId ? {...a, commentCount, preview} : a);
            tx.update(m.ref, {answers});
          });
        }
      } catch (e) {
        console.log(`onCommentPageWritten: ${postId}: ${e}`);
      }
    });

// onPostCreated keeps the server-side counts for a new answer:
// - the prompt's counts.answers
// - the author's FriendView/profile: stats.answers and the answer streak.
// The streak day is the post's promptDateId, not the server clock.
exports.onPostCreated = onDocumentCreated("Posts/{postId}", async (event) => {
  const post = event.data.data();
  const {uid, promptId, promptDateId} = post;
  if (!uid || !promptId || !isDayId(promptDateId)) {
    console.log(`onPostCreated: skipping ${event.params.postId}, ` +
        `missing uid/promptId/promptDateId`);
    return;
  }

  try {
    await db.collection("PromptDays").doc(promptDateId)
        .collection("Prompts").doc(promptId)
        .update({"counts.answers": FieldValue.increment(1)});
  } catch (e) {
    console.log(`onPostCreated: prompt ${promptDateId}/${promptId}: ${e}`);
  }

  try {
    const profileRef = db.collection("Users").doc(uid)
        .collection("FriendView").doc("profile");
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(profileRef);
      const profile = snap.exists ? snap.data() : {};
      const update = {stats: {answers: FieldValue.increment(1)}};
      const streak = markStreakDay(profile.streak, promptDateId);
      if (streak) update.streak = streak;
      tx.set(profileRef, update, {merge: true});
    });
  } catch (e) {
    console.log(`onPostCreated: profile ${uid}: ${e}`);
  }
});
