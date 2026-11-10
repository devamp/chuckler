// Account deletion: when a Firebase Auth user is deleted (from the app's
// Delete account button, or the console), everything they made goes too.
// App Store guideline 5.1.1(v) requires in-app deletion of the account and
// its data.

const {FieldValue} = require("firebase-admin/firestore");

/**
 * Deletes every doc a query returns, with their subcollections.
 * @param {object} db
 * @param {object} query
 * @return {Promise<number>} how many
 */
async function deleteAll(db, query) {
  const snap = await query.get();
  for (const doc of snap.docs) await db.recursiveDelete(doc.ref);
  return snap.size;
}

/**
 * Removes a deleted user's data:
 * - Users/{uid} with every subcollection (profile, private data, friends,
 *   requests, History, notifications), and their Usernames claim, so the
 *   name is free again
 * - their side on friends' lists (onFriendWritten lowers those counts)
 * - friend requests they sent, by username or by email
 * - their answers with comment threads, and the matchups those answers
 *   are in (with their Authors and Private docs)
 * - their friend prompts, votes and dislikes
 * - their comments on other people's answers (onCommentPageWritten then
 *   fixes counts and previews)
 * - their rows on the global leaderboards
 * Counts on other people's answers from their old votes are left as they
 * are.
 * @param {object} db
 * @param {string} uid
 * @return {Promise<object>} what was removed, by kind
 */
async function deleteUserData(db, uid) {
  const userRef = db.collection("Users").doc(uid);
  const user = (await userRef.get()).data() || {};
  const username = user.username || null;
  const done = {};

  // friends' lists
  const friends = await userRef.collection("Friends").get();
  for (const f of friends.docs) {
    await db.collection("Users").doc(f.id).collection("Friends").doc(uid)
        .delete();
  }
  done.friends = friends.size;

  // requests they sent (the docs carry the sender's username)
  if (username) {
    done.requests = await deleteAll(db, db.collectionGroup("FriendRequests")
        .where("username", "==", username)) +
      await deleteAll(db, db.collectionGroup("From")
          .where("username", "==", username));
  }

  // answers, and the matchups they're in
  const posts = await db.collection("Posts").where("uid", "==", uid).get();
  let matchups = 0;
  for (const p of posts.docs) {
    matchups += await deleteAll(db, db.collection("MatchUps")
        .where("postIds", "array-contains", p.id));
    await db.recursiveDelete(p.ref);
  }
  done.posts = posts.size;
  done.matchups = matchups;

  done.friendPrompts = await deleteAll(db,
      db.collection("FriendPrompts").where("creator.uid", "==", uid));
  done.votes = await deleteAll(db,
      db.collection("Votes").where("uid", "==", uid));
  done.dislikes = await deleteAll(db,
      db.collection("Dislikes").where("uid", "==", uid));

  // comments on other answers. Comment pages are maps, so this reads every
  // page; fine at this size.
  // TODO(scale): keep a `commenters` array on each page and query it.
  const pages = await db.collectionGroup("CommentPages").get();
  let comments = 0;
  for (const page of pages.docs) {
    const mine = Object.entries(page.data().comments || {})
        .filter(([, c]) => c && c.uid === uid).map(([k]) => k);
    if (mine.length === 0) continue;
    const update = {};
    for (const k of mine) update[`comments.${k}`] = FieldValue.delete();
    await page.ref.update(update);
    comments += mine.length;
  }
  done.comments = comments;

  if (username) {
    const boards = await db.collection("Leaderboards").get();
    for (const b of boards.docs) {
      const entries = b.data().entries || [];
      const kept = entries.filter((e) => e.username !== username);
      if (kept.length !== entries.length) {
        await b.ref.update({entries: kept});
      }
    }
    const claim = db.collection("Usernames").doc(username.toLowerCase());
    const owner = (await claim.get()).data()?.uid;
    if (owner === uid) await claim.delete();
  }

  await db.recursiveDelete(userRef);
  return done;
}

module.exports = {deleteUserData};
