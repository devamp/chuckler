// Global leaderboards: a public snapshot written once a prompt day ends
// (by finishDay), since strangers can't read each other's FriendView.
// Friends boards are worked out in the app from friends' profiles instead.
//
// Leaderboards/{board}: {board, dayId, weekStart?, entries, updatedAt}
//   answers      the day's top answers to daily prompts, with their authors
//   wins-week    stats for the week holding dayId (week.start == weekStart)
//   wins-all
//   posts-week
//   posts-all
//   streak       current answer streaks still alive at the end of dayId

const {FieldValue} = require("firebase-admin/firestore");
const {weekStart, addDays, daysBetween} = require("./promptDay");

const BOARD_SIZE = 50;
const ANSWER_BOARD_SIZE = 25;
// streaks are sorted on the stored `current`, which goes stale when a
// streak ends; read extra and drop the stale ones
const STREAK_SCAN = 200;

/**
 * An answer's place on the top answers board, best first: wins, then win
 * rate, then votes.
 * @param {object} a post data
 * @param {object} b post data
 * @return {number}
 */
function compareAnswers(a, b) {
  const ca = a.counts || {};
  const cb = b.counts || {};
  const rate = (c) => (c.wins || 0) / Math.max(1, c.votes || 0);
  return (cb.wins || 0) - (ca.wins || 0) ||
      rate(cb) - rate(ca) ||
      (cb.votes || 0) - (ca.votes || 0);
}

/**
 * The day's best answers to daily prompts. Friend prompt answers are left
 * out, so a friend prompt's audience stays private, and so are answers
 * nobody voted on.
 * @param {Array<{id: string, data: object}>} posts
 * @return {Array<{id: string, data: object}>}
 */
function topAnswers(posts) {
  return posts
      .filter((p) => p.data.uid && p.data.promptSource !== "friends" &&
          (p.data.counts?.votes || 0) > 0)
      .sort((a, b) => compareAnswers(a.data, b.data))
      .slice(0, ANSWER_BOARD_SIZE);
}

/**
 * A streak's current run as of the end of `dayId`: 0 if the streak's last
 * answered day is before it.
 * @param {object|undefined} streak {days, from, current}
 * @param {string} dayId
 * @return {number}
 */
function liveStreak(streak, dayId) {
  if (!streak || !streak.from || typeof streak.days !== "string") return 0;
  const last = addDays(streak.from, streak.days.length - 1);
  return daysBetween(last, dayId) > 0 ? 0 : (streak.current || 0);
}

/**
 * Usernames and photos for uids, leaving out official accounts.
 * @param {object} db
 * @param {Array<string>} uids
 * @return {Promise<Map<string, {username: string, photoUrl: string}>>}
 */
async function usersByUid(db, uids) {
  const out = new Map();
  if (uids.length === 0) return out;
  const snaps = await db.getAll(
      ...uids.map((u) => db.collection("Users").doc(u)));
  for (const s of snaps) {
    const d = s.data();
    if (!d || d.kind || !d.username) continue;
    out.set(s.id, {username: d.username, photoUrl: d.photoUrl || ""});
  }
  return out;
}

/**
 * Profiles ordered by a field, highest first, as [{uid, profile}].
 * @param {object} db
 * @param {string} field e.g. "stats.wins"
 * @param {number} limit
 * @param {string|null} week only profiles whose [weekField].start is this
 * @param {string} weekField "week" or "weekPrev"
 * @return {Promise<Array<{uid: string, profile: object}>>}
 */
async function topProfiles(db, field, limit, week = null, weekField = "week") {
  let q = db.collectionGroup("FriendView");
  if (week) q = q.where(`${weekField}.start`, "==", week);
  const snap = await q.orderBy(field, "desc").limit(limit).get();
  return snap.docs
      .filter((d) => d.id === "profile")
      .map((d) => ({uid: d.ref.parent.parent.id, profile: d.data()}));
}

/**
 * A weekly board's rows: profiles whose current week is `week`, plus
 * those who have since moved on to a newer week (kept in weekPrev).
 * @param {object} db
 * @param {string} stat "wins" or "answers"
 * @param {string} week the week's Monday
 * @return {Promise<Array<{uid: string, value: number}>>} best first
 */
async function weekRows(db, stat, week) {
  const [now, prev] = await Promise.all([
    topProfiles(db, `week.${stat}`, BOARD_SIZE * 2, week, "week"),
    topProfiles(db, `weekPrev.${stat}`, BOARD_SIZE * 2, week, "weekPrev"),
  ]);
  const byUid = new Map();
  for (const p of now) byUid.set(p.uid, p.profile.week?.[stat] || 0);
  for (const p of prev) {
    if (!byUid.has(p.uid)) byUid.set(p.uid, p.profile.weekPrev?.[stat] || 0);
  }
  return [...byUid].map(([uid, value]) => ({uid, value}))
      .sort((a, b) => b.value - a.value);
}

/**
 * Board rows from [{uid, value}], dropping zeros and unknown users.
 * @param {Array<{uid: string, value: number}>} rows sorted best first
 * @param {Map} users from usersByUid
 * @return {Array<object>} [{username, photoUrl, value}]
 */
function boardEntries(rows, users) {
  return rows
      .filter((r) => r.value > 0 && users.has(r.uid))
      .slice(0, BOARD_SIZE)
      .map((r) => ({...users.get(r.uid), value: r.value}));
}

/**
 * Writes every global board for the prompt day that just ended.
 * @param {object} db
 * @param {string} dayId
 * @param {Array<{id: string, data: object}>} posts the day's posts
 * @return {Promise<object>} entries per board
 */
async function writeLeaderboards(db, dayId, posts) {
  const week = weekStart(dayId);

  const [winsWeek, winsAll, postsWeek, postsAll, streaks] = await Promise.all([
    weekRows(db, "wins", week),
    topProfiles(db, "stats.wins", BOARD_SIZE * 2),
    weekRows(db, "answers", week),
    topProfiles(db, "stats.answers", BOARD_SIZE * 2),
    topProfiles(db, "streak.current", STREAK_SCAN),
  ]);
  const value = (field) => (p) => field.split(".")
      .reduce((o, k) => (o ? o[k] : undefined), p.profile) || 0;
  const rows = {
    "wins-week": winsWeek,
    "wins-all": winsAll.map((p) => ({uid: p.uid,
      value: value("stats.wins")(p)})),
    "posts-week": postsWeek,
    "posts-all": postsAll.map((p) => ({uid: p.uid,
      value: value("stats.answers")(p)})),
    "streak": streaks
        .map((p) => ({uid: p.uid, value: liveStreak(p.profile.streak, dayId)}))
        .sort((a, b) => b.value - a.value),
  };
  const answers = topAnswers(posts);

  const uids = new Set(answers.map((a) => a.data.uid));
  for (const list of Object.values(rows)) list.forEach((r) => uids.add(r.uid));
  const users = await usersByUid(db, [...uids]);

  const boards = {};
  for (const [id, list] of Object.entries(rows)) {
    boards[id] = boardEntries(list, users);
  }
  boards.answers = answers
      .filter((a) => users.has(a.data.uid))
      .map((a) => ({
        ...users.get(a.data.uid),
        postId: a.id,
        before: a.data.before || "",
        after: a.data.after || "",
        answer: a.data.answer || "",
        wins: a.data.counts?.wins || 0,
        votes: a.data.counts?.votes || 0,
      }));

  const batch = db.batch();
  for (const [id, entries] of Object.entries(boards)) {
    batch.set(db.collection("Leaderboards").doc(id), {
      board: id, dayId, entries,
      ...(id.endsWith("-week") ? {weekStart: week} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return Object.fromEntries(
      Object.entries(boards).map(([id, e]) => [id, e.length]));
}

module.exports = {
  writeLeaderboards, topAnswers, liveStreak, compareAnswers, boardEntries,
  BOARD_SIZE, ANSWER_BOARD_SIZE,
};
