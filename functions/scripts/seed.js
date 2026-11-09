// Seeds the LOCAL EMULATORS with fresh test data:
//   - the official Chuckler account (Users/chuckler + Usernames/chuckler)
//   - 8 test accounts in the Auth emulator (emails below, password
//     TEST_PASSWORD) with their Users, Usernames, FriendView and Private docs
//   - PromptDays for yesterday, today and the next 2 days (prompt days roll
//     over at 05:00 UTC), 3 Chuckler prompts each
//   - answers from every test account to today's prompts, so there is
//     something to vote on. With the functions emulator running, the
//     createMatchup function pairs them into matchups (4 per prompt).
// It overwrites the account and prompt docs if they exist, skips answers
// that already exist, and leaves everything else alone. Run it on fresh
// emulators: re-running resets the prompts' counts.
// It refuses to run unless FIRESTORE_EMULATOR_HOST is set, so it can't
// write to production.
//
// Run it (emulators started from the repo root, in another terminal):
//   firebase emulators:start
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
//     FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
//     npm --prefix functions run seed
//
// To make it the committed seed, export while the emulators are running
// (this replaces fb_em_data/, including the old export with real emails):
//   firebase emulators:export fb_em_data
// and from then on start with:
//   firebase emulators:start --import=fb_em_data
//
// Prompt days are relative to when you run this, so re-run it (and export
// again) when the seeded days have passed.

const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {
  promptDayId, promptDayStart, promptDayEnd, addDays,
} = require("../promptDay");

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  console.error("Refusing to seed: FIRESTORE_EMULATOR_HOST is not set, " +
      "so this would write to production. See the comment at the top.");
  process.exit(1);
}
// Never create accounts in production Auth either.
process.env.FIREBASE_AUTH_EMULATOR_HOST =
    process.env.FIREBASE_AUTH_EMULATOR_HOST || "127.0.0.1:9099";

const PROJECT_ID = process.env.GCLOUD_PROJECT || "chuckler-622ff";

// A test-only password for the emulator accounts below.
const TEST_PASSWORD = "chuckler-test-1";

const CHUCKLER = {
  uid: "chuckler",
  username: "Chuckler",
  bio: "Professional blank-filler. I write the prompts, you do the funny " +
      "part. 🤡",
};

const TEST_USERS = [
  {uid: "test-ava", username: "ava", email: "ava@chuckler.test", age: 24},
  {uid: "test-ben", username: "ben", email: "ben@chuckler.test", age: 31},
  {uid: "test-cleo", username: "cleo", email: "cleo@chuckler.test", age: 19},
  {uid: "test-dev", username: "dev", email: "dev@chuckler.test", age: 22},
  {uid: "test-eli", username: "eli", email: "eli@chuckler.test", age: 27},
  {uid: "test-fay", username: "fay", email: "fay@chuckler.test", age: 20},
  {uid: "test-gus", username: "gus", email: "gus@chuckler.test", age: 35},
  {uid: "test-hal", username: "hal", email: "hal@chuckler.test", age: 18},
];

// Today's answers, one per test account (in TEST_USERS order) per prompt.
const TODAY_ANSWERS = [
  [
    "they missed the group project deadline",
    "a meteor, but it was a gender reveal",
    "they kept replying-all",
    "unpaid internships",
    "the floor was lava, for real",
    "they all moved to Florida",
    "Jurassic rent prices",
    "nobody told them about the asteroid group chat",
  ],
  [
    "say \"per my last email\"",
    "microwave fish at work",
    "watch my own Instagram stories",
    "argue with toddlers",
    "fake laugh at my boss",
    "name my houseplants after exes",
    "buy candles",
    "check my ex's Spotify",
  ],
  [
    "a voice memo of me chewing",
    "my screen time report",
    "\"who wants to see my feet\"",
    "a selfie with my mom's boyfriend",
    "my LinkedIn post",
    "the wrong screenshot",
    "a 4-minute Minion video",
    "\"k\"",
  ],
];

// 3 prompts per day: day offset -1 (yesterday) to +2.
const PROMPTS = [
  [
    ["The worst thing to say on a first date is ", "."],
    ["My grandma's secret ingredient is ", "."],
    ["Nobody at this school knows I ", "."],
  ],
  [
    ["The real reason dinosaurs went extinct: ", "."],
    ["My new year's resolution is to ", " less."],
    ["The group chat went silent after I sent ", "."],
  ],
  [
    ["A terrible name for a boat: ", "."],
    ["This town's best-kept secret is ", "."],
    ["The last thing I'd want my friends to find in my room: ", "."],
  ],
  [
    ["If my dog could talk, the first thing it'd say is ", "."],
    ["The local news headline nobody expected: ", "."],
    ["Our friend group's unofficial motto is ", "."],
  ],
];
const LOCATIONS = ["global", "local", "friends"];

/**
 * Creates or updates an Auth emulator account with a fixed uid.
 * @param {object} auth
 * @param {object} u
 */
async function upsertAuthUser(auth, u) {
  const props = {email: u.email, password: TEST_PASSWORD,
    displayName: u.username, emailVerified: true};
  try {
    await auth.updateUser(u.uid, props);
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    await auth.createUser({uid: u.uid, ...props});
  }
}

/** Seeds everything. */
async function main() {
  initializeApp({projectId: PROJECT_ID});
  const db = getFirestore();
  const auth = getAuth();
  const batch = db.batch();

  // The official account. Its username is reserved so nobody can take it.
  batch.set(db.doc(`Users/${CHUCKLER.uid}`), {
    username: CHUCKLER.username, profileImage: "", kind: "official",
    bio: CHUCKLER.bio,
  });
  batch.set(db.doc(`Usernames/${CHUCKLER.username.toLowerCase()}`),
      {uid: CHUCKLER.uid});

  // Test accounts, laid out like registerNewUser in lib/data/users.dart.
  for (const u of TEST_USERS) {
    await upsertAuthUser(auth, u);
    batch.set(db.doc(`Users/${u.uid}`), {
      username: u.username, profileImage: "",
      friends: 0, pendingFriends: 0, posts: 0,
    });
    batch.set(db.doc(`Usernames/${u.username.toLowerCase()}`), {uid: u.uid});
    batch.set(db.doc(`Users/${u.uid}/FriendView/profile`),
        {bio: "", stats: {answers: 0}});
    batch.set(db.doc(`Users/${u.uid}/Private/account`), {age: u.age});
  }

  // Prompt days, relative to now.
  const today = promptDayId(new Date());
  const days = [];
  PROMPTS.forEach((prompts, i) => {
    const dayId = addDays(today, i - 1);
    days.push(dayId);
    batch.set(db.doc(`PromptDays/${dayId}`), {
      date: Timestamp.fromDate(new Date(`${dayId}T00:00:00Z`)),
      opensAt: Timestamp.fromDate(promptDayStart(dayId)),
      endsAt: Timestamp.fromDate(promptDayEnd(dayId)),
    });
    prompts.forEach(([before, after], j) => {
      batch.set(db.doc(`PromptDays/${dayId}/Prompts/p${j + 1}`), {
        before, after, kind: "fill",
        location: LOCATIONS[(i + j) % LOCATIONS.length],
        creator: {uid: CHUCKLER.uid, username: CHUCKLER.username,
          photoUrl: "", kind: "official"},
        counts: {answers: 0, likes: 0},
        likedBy: [],
      });
    });
  });

  await batch.commit();

  // Today's answers, written one at a time like the app's createPost (post
  // + History entry) so the functions emulator handles each in turn.
  let answers = 0;
  for (const [j, prompt] of PROMPTS[1].entries()) {
    const promptId = `p${j + 1}`;
    for (const [k, u] of TEST_USERS.entries()) {
      const postRef = db.doc(`Posts/seed-${today}-${promptId}-${u.uid}`);
      if ((await postRef.get()).exists) continue;
      const answer = TODAY_ANSWERS[j][k];
      const at = Timestamp.fromDate(new Date(Date.now() - (60 - answers) *
          60 * 1000));
      const post = db.batch();
      post.set(postRef, {
        answer, uid: u.uid, username: u.username, promptId,
        promptDateId: today, date: at, likes: 0, dislikes: 0, wins: 0,
        random: Math.floor(Math.random() * 1000000),
        before: prompt[0], after: prompt[1], status: "active",
        counts: {matchups: 0, votes: 0, wins: 0, dislikes: 0, likes: 0,
          comments: 0},
      });
      post.set(db.doc(`Users/${u.uid}/History/${today.substring(0, 7)}`), {
        answers: {[`${today}_${promptId}`]: {
          postId: postRef.id, promptDateId: today, promptId,
          before: prompt[0], after: prompt[1], answer, at,
        }},
      }, {merge: true});
      await post.commit();
      answers++;
      // give createMatchup a moment, so answers pair in order
      await new Promise((r) => setTimeout(r, 300));
    }
  }

  console.log(`Seeded project ${PROJECT_ID} on ` +
      `${process.env.FIRESTORE_EMULATOR_HOST}:`);
  console.log(`  prompt days ${days.join(", ")} (today is ${today})`);
  console.log(`  accounts ${TEST_USERS.map((u) => u.email).join(", ")} ` +
      `(password: ${TEST_PASSWORD})`);
  console.log(`  ${answers} new answers to today's prompts`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
