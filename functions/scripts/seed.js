// Seeds the LOCAL EMULATORS with fresh test data:
//   - the official Chuckler account (Users/chuckler + Usernames/chuckler)
//   - 8 test accounts in the Auth emulator (emails below, password
//     TEST_PASSWORD) with their Users, Usernames, FriendView and Private docs
//   - PromptDays for yesterday, today and the next 2 days (prompt days roll
//     over at 05:00 UTC), 3 Chuckler prompts each
//   - friends: ava, ben and cleo are friends with each other; dev has sent
//     ava a request by username and eli one to ava's email, so ava has 2
//     friends and 2 requests waiting
//   - answers from every test account to today's prompts, so there is
//     something to vote on. With the functions emulator running, the
//     createMatchup function pairs them into matchups (4 per prompt).
//   - ben and cleo each write a friend prompt (seen by ava, ben and cleo),
//     and both answer ben's: a friends matchup ava can vote on.
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
//
// For wins and leaderboards, have the test accounts vote on yesterday's
// matchups, then recount and finish the day:
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix functions run \
//     seed:votes
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix functions run recount
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix functions run \
//     finish-day -- --force
//
// After the 05:00 UTC rollover, today's prompts have no answers and Home has
// nothing to vote on. To fix that on running emulators without touching
// accounts, prompts, friends or streaks, answer just today's prompts:
//   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 \
//     FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
//     npm --prefix functions run seed:answers

const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const crypto = require("crypto");
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

// Answers to every seeded prompt, one per test account (in TEST_USERS
// order), keyed by the prompt's opening text. Whichever prompts are live
// today get answered from here.
const ANSWERS = {
  "The worst thing to say on a first date is ": [
    "\"my mom picked this outfit\"",
    "\"so anyway, my ex\"",
    "\"do you want to split this 9 ways\"",
    "\"I already named our kids\"",
    "\"I'm technically still married\"",
    "\"wait, which app was this\"",
    "\"I brought my lawyer\"",
    "\"same time next week?\" before the food comes",
  ],
  "My grandma's secret ingredient is ": [
    "spite",
    "a little bit of Pall Mall ash",
    "store-bought, don't tell anyone",
    "the neighbor's basil",
    "three sticks of butter per serving",
    "Mountain Dew",
    "guilt",
    "a recipe she stole in 1974",
  ],
  "Nobody at this school knows I ": [
    "still sleep with a nightlight",
    "run the anonymous confessions page",
    "failed the swim test 4 times",
    "am 31",
    "live in the library",
    "cried at the pep rally",
    "can't actually read cursive",
    "am the mascot",
  ],
  "The real reason dinosaurs went extinct: ": [
    "they missed the group project deadline",
    "a meteor, but it was a gender reveal",
    "they kept replying-all",
    "unpaid internships",
    "the floor was lava, for real",
    "they all moved to Florida",
    "Jurassic rent prices",
    "nobody told them about the asteroid group chat",
  ],
  "My new year's resolution is to ": [
    "say \"per my last email\"",
    "microwave fish at work",
    "watch my own Instagram stories",
    "argue with toddlers",
    "fake laugh at my boss",
    "name my houseplants after exes",
    "buy candles",
    "check my ex's Spotify",
  ],
  "The group chat went silent after I sent ": [
    "a voice memo of me chewing",
    "my screen time report",
    "\"who wants to see my feet\"",
    "a selfie with my mom's boyfriend",
    "my LinkedIn post",
    "the wrong screenshot",
    "a 4-minute Minion video",
    "\"k\"",
  ],
  "A terrible name for a boat: ": [
    "The Titanic 2",
    "Leaky Lucy",
    "Unsinkable (Probably)",
    "Midlife Crisis",
    "Her Alimony",
    "Davy Jones' Locker Room",
    "Sir Floats-a-Little",
    "Reel Estate Debt",
  ],
  "This town's best-kept secret is ": [
    "the mayor is three raccoons in a coat",
    "the Applebee's never closes",
    "the lake is actually a puddle",
    "the speed limit signs are suggestions",
    "the library has a bar in the back",
    "everyone's dating the same guy",
    "the water tower is hollow",
    "nobody actually likes the parade",
  ],
  "The last thing I'd want my friends to find in my room: ": [
    "my fan fiction folder",
    "a shrine to my old crush",
    "my mom",
    "a signed Nickelback poster",
    "my diary from last week",
    "the 40 Crocs",
    "my ex, hiding in the closet",
    "a printed photo of my own LinkedIn",
  ],
  "If my dog could talk, the first thing it'd say is ": [
    "\"I've seen what you do in the shower\"",
    "\"the mailman and I are engaged\"",
    "\"you call that a walk?\"",
    "\"I ate your AirPods, both times\"",
    "\"who's a good boy? Not you\"",
    "\"I want a lawyer\"",
    "\"that cat is my landlord\"",
    "\"I'm actually a cat\"",
  ],
  "The local news headline nobody expected: ": [
    "Goose Elected to School Board",
    "Man Finally Reads Terms and Conditions",
    "Local Mom Reaches Inbox Zero",
    "Walmart Greeter Says Goodbye",
    "Town Pothole Gets Its Own Zip Code",
    "Area Teen Calls Grandma Unprompted",
    "Weatherman Admits He Was Guessing",
    "Pigeon Steals Entire Pizza, Shares It",
  ],
  "Our friend group's unofficial motto is ": [
    "\"we'll Venmo you later\"",
    "\"it's not a party until someone cries\"",
    "\"who's driving?\" (nobody)",
    "\"left on read, right on time\"",
    "\"one more episode\"",
    "\"it's giving debt\"",
    "\"we don't talk about Cancun\"",
    "\"plans are just suggestions\"",
  ],
};

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

/**
 * Answers today's live prompts as every test account, written one at a time
 * like the app's createPost (post + History entry) so the functions emulator
 * pairs them into matchups in turn. Skips answers that already exist and
 * prompts with no seeded answers.
 * @param {object} db
 * @param {string} today the prompt day id
 * @return {Promise<number>} how many answers were written
 */
async function answerToday(db, today) {
  const prompts = await db.collection(`PromptDays/${today}/Prompts`).get();
  if (prompts.empty) {
    throw new Error(`No prompts for today (${today}). Run the full seed.`);
  }
  let answers = 0;
  for (const doc of prompts.docs) {
    const promptId = doc.id;
    const {before, after} = doc.data();
    const texts = ANSWERS[before];
    if (!texts) {
      console.log(`  no seeded answers for "${before}", skipped`);
      continue;
    }
    for (const [k, u] of TEST_USERS.entries()) {
      const postRef = db.doc(`Posts/seed-${today}-${promptId}-${u.uid}`);
      if ((await postRef.get()).exists) continue;
      const answer = texts[k];
      const at = Timestamp.fromDate(new Date(Date.now() - (60 - answers) *
          60 * 1000));
      const post = db.batch();
      post.set(postRef, {
        answer, uid: u.uid, username: u.username, promptId,
        promptDateId: today, date: at, likes: 0, dislikes: 0, wins: 0,
        random: Math.floor(Math.random() * 1000000),
        before, after, status: "active",
        counts: {matchups: 0, votes: 0, wins: 0, dislikes: 0, likes: 0,
          comments: 0},
      });
      post.set(db.doc(`Users/${u.uid}/History/${today.substring(0, 7)}`), {
        answers: {[`${today}_${promptId}`]: {
          postId: postRef.id, promptDateId: today, promptId,
          before, after, answer, at,
        }},
      }, {merge: true});
      await post.commit();
      answers++;
      // give createMatchup a moment, so answers pair in order
      await new Promise((r) => setTimeout(r, 300));
    }
  }
  return answers;
}

// Friend prompts for today, by uid: written like the app's
// createFriendPrompt, with the audience left to onFriendPromptCreated.
const FRIEND_PROMPTS = {
  "test-ben": ["The real reason ben is always late: ", "."],
  "test-cleo": ["cleo's next tattoo should say ", "."],
};
// Answers to ben's friend prompt, so ava has a friends matchup to vote on.
const FRIEND_ANSWERS = {
  "test-ben": "a time zone of my own",
  "test-cleo": "he's been in the parking lot for an hour",
};

/**
 * ben and cleo each write a friend prompt today (their audience is each
 * other and ava), and they both answer ben's, which makes one matchup only
 * ava, ben and cleo can see. Needs the functions emulator. Skips what
 * already exists.
 * @param {object} db
 * @param {string} today
 * @return {Promise<number>} answers written
 */
async function seedFriendPrompts(db, today) {
  const byUid = Object.fromEntries(TEST_USERS.map((u) => [u.uid, u]));
  for (const [uid, [before, after]] of Object.entries(FRIEND_PROMPTS)) {
    const ref = db.doc(`FriendPrompts/${uid}_${today}`);
    if ((await ref.get()).exists) continue;
    await ref.set({
      before, after, kind: "fill", dayId: today,
      createdAt: Timestamp.now(), status: "active",
      creator: {uid, username: byUid[uid].username, photoUrl: ""},
      counts: {answers: 0, likes: 0, dislikes: 0}, likedBy: [],
    });
  }
  // the audience comes from the function
  for (let i = 0; i < 20; i++) {
    const p = await db.doc(`FriendPrompts/test-ben_${today}`).get();
    if (p.data()?.audience) break;
    await new Promise((r) => setTimeout(r, 300));
  }
  const promptId = `test-ben_${today}`;
  const [before, after] = FRIEND_PROMPTS["test-ben"];
  let written = 0;
  for (const [uid, answer] of Object.entries(FRIEND_ANSWERS)) {
    const postRef = db.doc(`Posts/seed-${promptId}-${uid}`);
    if ((await postRef.get()).exists) continue;
    const at = Timestamp.now();
    const batch = db.batch();
    batch.set(postRef, {
      answer, uid, username: byUid[uid].username, promptId,
      promptDateId: today, promptSource: "friends", date: at,
      likes: 0, dislikes: 0, wins: 0, random: 1, before, after,
      status: "active", counts: {matchups: 0, votes: 0, wins: 0,
        dislikes: 0, likes: 0, comments: 0},
    });
    batch.set(db.doc(`Users/${uid}/History/${today.substring(0, 7)}`), {
      answers: {[`${today}_${promptId}`]: {
        postId: postRef.id, promptDateId: today, promptId,
        before, after, answer, at,
      }},
    }, {merge: true});
    await batch.commit();
    written++;
    await new Promise((r) => setTimeout(r, 300));
  }
  return written;
}

/**
 * Has up to four test accounts vote on each public matchup of `dayId`
 * (never on their own answers), so wins, results and the leaderboards have
 * something in them. Each voter's pick is fixed by their uid and the
 * matchup, so re-running adds nothing. Needs the functions emulator, whose
 * onVoteCreated counts the votes.
 * @param {object} db
 * @param {string} dayId
 * @return {Promise<number>} votes cast
 */
async function seedVotes(db, dayId) {
  const matchups = await db.collection("MatchUps")
      .where("promptDateId", "==", dayId)
      .where("scope", "==", "public").get();
  let n = 0;
  for (const m of matchups.docs) {
    const owners = (await m.ref.collection("Private").doc("owners").get())
        .data()?.uids || [];
    const voters = TEST_USERS.filter((u) => !owners.includes(u.uid))
        .slice(0, 4);
    for (const u of voters) {
      const ref = db.doc(`Votes/${m.id}_${u.uid}`);
      if ((await ref.get()).exists) continue;
      const pick = crypto.createHash("sha256").update(m.id + u.uid)
          .digest()[0] % 3 === 0 ? 1 : 0;
      await ref.set({uid: u.uid, matchupId: m.id, card: pick, type: "win",
        promptDateId: dayId, at: Timestamp.now()});
      n++;
    }
  }
  return n;
}

/** Seeds everything, or with --answers / --votes only that part. */
async function main() {
  initializeApp({projectId: PROJECT_ID});
  const db = getFirestore();
  const today = promptDayId(new Date());

  // --answers: only answer today's prompts, leaving accounts, prompts and
  // friends as they are. For when the day rolls over on running emulators.
  // --votes [day]: test accounts vote on that day's matchups (default
  // yesterday), for wins and leaderboards. Then run recount and finish-day.
  if (process.argv.includes("--votes")) {
    const i = process.argv.indexOf("--votes");
    const dayId = process.argv[i + 1] || addDays(today, -1);
    const votes = await seedVotes(db, dayId);
    console.log(`${votes} votes on ${dayId}'s matchups on ` +
        `${process.env.FIRESTORE_EMULATOR_HOST}`);
    return;
  }

  if (process.argv.includes("--answers")) {
    const answers = await answerToday(db, today);
    const friendAnswers = await seedFriendPrompts(db, today);
    console.log(`${answers} new answers to today's prompts (${today}) and ` +
        `${friendAnswers} to ben's friend prompt on ` +
        `${process.env.FIRESTORE_EMULATOR_HOST}`);
    return;
  }

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

  // Friends, laid out like lib/data/friends.dart.
  const byName = Object.fromEntries(TEST_USERS.map((u) => [u.username, u]));
  const now = Timestamp.now();
  const friendPairs = [["ava", "ben"], ["ava", "cleo"], ["ben", "cleo"]];
  for (const [a, b] of friendPairs) {
    for (const [me, them] of [[byName[a], byName[b]], [byName[b], byName[a]]]) {
      batch.set(db.doc(`Users/${me.uid}/Friends/${them.uid}`),
          {username: them.username, photoUrl: "", since: now});
    }
  }
  const card = (u) => ({username: u.username, photoUrl: "", sentAt: now});
  batch.set(db.doc(`Users/${byName.ava.uid}/FriendRequests/${byName.dev.uid}`),
      card(byName.dev));
  const avaEmailHash = crypto.createHash("sha256")
      .update(byName.ava.email.toLowerCase()).digest("hex");
  batch.set(db.doc(`EmailRequests/${avaEmailHash}/From/${byName.eli.uid}`),
      card(byName.eli));

  await batch.commit();

  const answers = await answerToday(db, today);
  const friendAnswers = await seedFriendPrompts(db, today);

  console.log(`Seeded project ${PROJECT_ID} on ` +
      `${process.env.FIRESTORE_EMULATOR_HOST}:`);
  console.log(`  prompt days ${days.join(", ")} (today is ${today})`);
  console.log(`  accounts ${TEST_USERS.map((u) => u.email).join(", ")} ` +
      `(password: ${TEST_PASSWORD})`);
  console.log("  friends: ava, ben, cleo; ava has requests from dev " +
      "(username) and eli (email)");
  console.log(`  ${answers} new answers to today's prompts`);
  console.log(`  friend prompts by ben and cleo; ${friendAnswers} answers ` +
      "to ben's (a friends matchup for ava)");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
