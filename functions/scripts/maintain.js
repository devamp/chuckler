// Maintenance for the LOCAL EMULATORS (refuses to run without
// FIRESTORE_EMULATOR_HOST, so it can't touch production):
//
//   finish-day [yyyy-MM-dd] [--force]
//     Runs the daily results for a prompt day (default: yesterday), as the
//     dailyResults schedule does in production: final stats into each
//     author's History, and a results notification each. The emulator
//     doesn't run schedules, so this stands in for it.
//
//   migrate
//     Gives matchups from before scopes existed scope "public", so the Home
//     tab's public query finds them.
//
//   leaderboards [yyyy-MM-dd]
//     Rewrites the global leaderboards as of a prompt day (default:
//     yesterday), as finish-day does, without touching results.
//
//   recount
//     Recomputes every user's stats (answers, wins, comments, friends),
//     streak and this week's counts from the data, and awards any tiers
//     they qualify for. Use it to backfill after adding a stat or an award
//     tier, or to fix drift.
//
// Run from the repo root with the emulators running:
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix functions run recount
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
//     npm --prefix functions run finish-day -- 2026-11-08

const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {promptDayId, addDays, markStreakDay, weekStart} =
    require("../promptDay");
const {finishDay} = require("../results");
const {writeLeaderboards} = require("../leaderboards");
const {newAwards} = require("../awards");
const {profileRef, notificationRef, notification} = require("../profile");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error("Refusing to run: FIRESTORE_EMULATOR_HOST is not set, " +
      "so this would write to production.");
  process.exit(1);
}

initializeApp({projectId: process.env.GCLOUD_PROJECT || "chuckler-622ff"});
const db = getFirestore();

/**
 * Recounts one user's stats and streak, and awards what they qualify for.
 * @param {string} uid
 * @param {Map<string, number>} comments comments written, by uid
 * @return {Promise<object>} the new stats
 */
async function recountUser(uid, comments) {
  const posts = await db.collection("Posts").where("uid", "==", uid).get();
  let wins = 0;
  const days = new Set();
  const thisWeek = weekStart(promptDayId(new Date()));
  const week = {start: thisWeek, answers: 0, wins: 0};
  const weekPrev = {start: addDays(thisWeek, -7), answers: 0, wins: 0};
  for (const p of posts.docs) {
    const day = p.data().promptDateId;
    wins += p.data().counts?.wins || 0;
    if (day) days.add(day);
    for (const w of [week, weekPrev]) {
      if (day && weekStart(day) === w.start) {
        w.answers++;
        w.wins += p.data().counts?.wins || 0;
      }
    }
  }
  let streak;
  for (const day of [...days].sort()) {
    streak = markStreakDay(streak, day) || streak;
  }
  const friends = (await db.collection("Users").doc(uid)
      .collection("Friends").count().get()).data().count;
  const stats = {answers: posts.size, wins, comments: comments.get(uid) || 0,
    friends};

  const ref = profileRef(db, uid);
  const snap = await ref.get();
  const profile = snap.exists ? snap.data() : {};
  const after = {...profile, stats: {...profile.stats, ...stats},
    ...(streak ? {streak} : {})};
  const awards = newAwards(after);
  const update = {stats, week, weekPrev, ...(streak ? {streak} : {})};
  for (const a of awards) {
    update.awards = update.awards || {};
    update.awards[a.id] = {...(update.awards[a.id] || {}),
      [String(a.at)]: FieldValue.serverTimestamp()};
  }
  const batch = db.batch();
  batch.set(ref, update, {merge: true});
  for (const a of awards) {
    batch.set(notificationRef(db, uid), notification("award",
        `You earned ${a.name}!`, {award: {id: a.id, at: a.at}}));
  }
  await batch.commit();
  return {...stats, week, awards: awards.map((a) => a.name)};
}

/** Recounts everyone. */
async function recount() {
  const comments = new Map();
  const pages = await db.collectionGroup("CommentPages").get();
  for (const page of pages.docs) {
    for (const c of Object.values(page.data().comments || {})) {
      if (c.uid) comments.set(c.uid, (comments.get(c.uid) || 0) + 1);
    }
  }
  const users = await db.collection("Users").get();
  for (const u of users.docs) {
    if (u.data().kind) continue; // official accounts don't post
    const result = await recountUser(u.id, comments);
    console.log(`  ${u.data().username || u.id}: ${JSON.stringify(result)}`);
  }
}

/**
 * Gives matchups made before scopes existed scope "public", so the Home
 * tab's public query (scope == "public") finds them.
 */
async function migrate() {
  const matchups = await db.collection("MatchUps").get();
  const writer = db.bulkWriter();
  let n = 0;
  for (const m of matchups.docs) {
    if (m.data().scope) continue;
    writer.update(m.ref, {scope: "public"});
    n++;
  }
  await writer.close();
  console.log(`migrate: ${n} matchups given scope "public"`);
}

/** Runs the command named on the command line. */
async function main() {
  const [command, ...args] = process.argv.slice(2);
  if (command === "recount") {
    await recount();
  } else if (command === "migrate") {
    await migrate();
  } else if (command === "leaderboards") {
    const dayId = args[0] || addDays(promptDayId(new Date()), -1);
    const posts = await db.collection("Posts")
        .where("promptDateId", "==", dayId).get();
    const result = await writeLeaderboards(db, dayId,
        posts.docs.map((d) => ({id: d.id, data: d.data()})));
    console.log(`leaderboards ${dayId}: ${JSON.stringify(result)}`);
  } else if (command === "finish-day") {
    const dayId = args.find((a) => !a.startsWith("--")) ||
        addDays(promptDayId(new Date()), -1);
    const result = await finishDay(db, dayId,
        {force: args.includes("--force")});
    console.log(`finish-day ${dayId}: ${JSON.stringify(result)}`);
  } else {
    console.error("usage: maintain.js recount | migrate | " +
        "finish-day [day] [--force] | leaderboards [day]");
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
