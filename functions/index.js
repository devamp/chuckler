const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {isDayId, markStreakDay} = require("./promptDay");
initializeApp();
const db = getFirestore();


// createMatchups runs every time a new post occurs
// creates matchup with unmatched post
// and if no match exists sets the matched key to false.

exports.createMatchup = onDocumentCreated("Posts/{docid}", async (event) => {
  const eData = event.data.data();
  try {
    // Find a post that does not have a match up
    const matchingPost = await db.collection("Posts")
        .where("promptId", "==", eData.promptId)
        .where("promptDateId", "==", eData.promptDateId)
        .where("matched", "==", false)
        .orderBy("date", "asc")
        .limit(1).get();
    // Check if a match up was found
    if (matchingPost == null || matchingPost.empty) {
      // eslint-disable-next-line max-len
      await db.collection("Posts").doc(event.data.id).update({"matched": false});
    } else {
      // Create the match up and set the found posts matched flag to true
      await matchingPost.docs[0].ref.update(
          {"matched": true},
      );
      const mPD = matchingPost.docs[0].data();
      await db.collection("MatchUps").doc().set({
        answer1: eData.answer,
        uid1: eData.uid,
        postId1: event.data.id,
        username1: eData.username,
        wins1: 0,
        answer2: mPD.answer,
        uid2: mPD.uid,
        username2: mPD.username,
        postId2: matchingPost.docs[0].id,
        wins2: 0,
        views: 0,
        promptId: eData.promptId,
        promptDateId: mPD.promptDateId,
      });
    }
  } catch (e) {
    console.log(e);
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
