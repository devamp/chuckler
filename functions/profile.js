// A user's server-kept profile (Users/{uid}/FriendView/profile): stats,
// streak and awards, plus their Notifications. Only functions write these.

const {FieldValue} = require("firebase-admin/firestore");
const {newAwards} = require("./awards");
const {weekStart} = require("./promptDay");

// stats also counted per week, for the weekly leaderboards
const WEEK_STATS = ["answers", "wins"];

/**
 * The profile's `week` after adding `deltas` for prompt day `day`:
 * {start, answers, wins}, where start is the week's Monday. A newer week
 * starts again from zero; a change for an older week than the stored one
 * (a late vote) leaves it alone. null when nothing weekly changes.
 * @param {object|undefined} week the stored week
 * @param {string|null} day the prompt day the change belongs to
 * @param {object} deltas {stat: n}
 * @return {object|null}
 */
function nextWeek(week, day, deltas) {
  const keys = Object.keys(deltas).filter((k) => WEEK_STATS.includes(k));
  if (!day || keys.length === 0) return null;
  const start = weekStart(day);
  const stored = week && week.start ? week : null;
  if (stored && stored.start > start) return null;
  const base = stored && stored.start === start ? stored : {};
  // every field written, so a reset can't leave last week's counts behind
  const next = {start};
  for (const k of WEEK_STATS) next[k] = base[k] || 0;
  for (const k of keys) next[k] = Math.max(0, next[k] + deltas[k]);
  return next;
}

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
 * @param {object} change {deltas: {stat: n}, streak: new streak or null,
 *     day: the prompt day it belongs to, for the weekly counts}
 * @return {Array<object>} the awards earned
 */
function applyStats(tx, db, uid, profile,
    {deltas = {}, streak = null, day = null} = {}) {
  const stats = {...(profile.stats || {})};
  const update = {};
  for (const [key, n] of Object.entries(deltas)) {
    stats[key] = Math.max(0, (stats[key] || 0) + n);
    update.stats = {...(update.stats || {}), [key]: stats[key]};
  }
  if (streak) update.streak = streak;
  const week = nextWeek(profile.week, day, deltas);
  if (week) {
    update.week = week;
    // a new week keeps the last one, so the weekly board written just
    // after the rollover still finds people who've already answered
    if (profile.week?.start && profile.week.start < week.start) {
      update.weekPrev = profile.week;
    }
  }
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
  nextWeek, WEEK_STATS,
};
