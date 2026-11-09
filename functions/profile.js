// A user's server-kept profile (Users/{uid}/FriendView/profile): stats,
// streak and awards, plus their Notifications. Only functions write these.

const {FieldValue} = require("firebase-admin/firestore");
const {newAwards} = require("./awards");

/**
 * @param {object} db
 * @param {string} uid
 * @return {object} the profile doc ref
 */
function profileRef(db, uid) {
  return db.collection("Users").doc(uid)
      .collection("FriendView").doc("profile");
}

/**
 * A new notification doc ref for `uid`.
 * @param {object} db
 * @param {string} uid
 * @return {object}
 */
function notificationRef(db, uid) {
  return db.collection("Users").doc(uid).collection("Notifications").doc();
}

/**
 * A notification's fields.
 * @param {string} type friendRequest, friendAdded, award, comment, results
 * @param {string} text what the user reads
 * @param {object} extra e.g. from {username, photoUrl}, postId, award
 * @return {object}
 */
function notification(type, text, extra = {}) {
  return {type, text, at: FieldValue.serverTimestamp(), seen: false, ...extra};
}

/**
 * Applies stat changes to a profile read earlier in the same transaction,
 * and awards any tiers the new stats reach (with a notification each).
 * Call it after all of the transaction's reads.
 * @param {object} tx the transaction
 * @param {object} db
 * @param {string} uid
 * @param {object} profile the profile's current data ({} if none)
 * @param {object} change {deltas: {stat: n}, streak: new streak or null}
 * @return {Array<object>} the awards earned
 */
function applyStats(tx, db, uid, profile, {deltas = {}, streak = null} = {}) {
  const stats = {...(profile.stats || {})};
  const update = {};
  for (const [key, n] of Object.entries(deltas)) {
    stats[key] = Math.max(0, (stats[key] || 0) + n);
    update.stats = {...(update.stats || {}), [key]: stats[key]};
  }
  if (streak) update.streak = streak;
  const after = {...profile, stats, ...(streak ? {streak} : {})};
  const awards = newAwards(after);
  for (const a of awards) {
    update.awards = update.awards || {};
    update.awards[a.id] = {...(update.awards[a.id] || {}),
      [String(a.at)]: FieldValue.serverTimestamp()};
  }
  if (Object.keys(update).length === 0) return [];
  tx.set(profileRef(db, uid), update, {merge: true});
  for (const a of awards) {
    tx.set(notificationRef(db, uid), notification("award",
        `You earned ${a.name}!`, {award: {id: a.id, at: a.at}}));
  }
  return awards;
}

/**
 * Reads a profile and applies stat changes in its own transaction.
 * @param {object} db
 * @param {string} uid
 * @param {object} deltas {stat: n}
 * @return {Promise<Array<object>>} the awards earned
 */
async function bumpStats(db, uid, deltas) {
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(profileRef(db, uid));
    return applyStats(tx, db, uid, snap.exists ? snap.data() : {}, {deltas});
  });
}

/**
 * Shortens text for a notification.
 * @param {string} s
 * @param {number} n
 * @return {string}
 */
function clip(s, n = 40) {
  s = String(s || "");
  return s.length > n ? s.substring(0, n - 1).trimEnd() + "…" : s;
}

module.exports = {
  profileRef, notificationRef, notification, applyStats, bumpStats, clip,
};
