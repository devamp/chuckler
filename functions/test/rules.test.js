// Firestore rules tests. Run with the emulator:
//   firebase emulators:exec --only firestore "npm --prefix functions test"
// Uses its own demo project id, so it never touches the dev emulator data
// (or production).

const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc, getDoc, setDoc, updateDoc, deleteDoc,
  arrayUnion, arrayRemove, increment, setLogLevel,
  writeBatch, collection, getDocs, runTransaction, Timestamp,
  query, where, orderBy, serverTimestamp,
} = require("firebase/firestore");
const {promptDayId, addDays} = require("../promptDay");

// Denied writes are expected here; don't log each one.
setLogLevel("error");

const PROMPT = "PromptDays/2026-11-08/Prompts/p1";

let env;

/**
 * A Firestore client signed in as `uid`.
 * @param {string} uid
 * @return {object}
 */
function as(uid) {
  return env.authenticatedContext(uid).firestore();
}

/**
 * Writes docs with rules switched off.
 * @param {object} docs path -> data
 */
async function seed(docs) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    for (const [p, data] of Object.entries(docs)) {
      await setDoc(doc(db, p), data);
    }
  });
}

/**
 * A valid new post by `uid`.
 * @param {string} uid
 * @param {object} extra fields to add or override
 * @return {object}
 */
function newPost(uid, extra = {}) {
  return {
    answer: "a goose", uid, username: uid, promptId: "p1",
    promptDateId: "2026-11-08", date: new Date(),
    before: "My ", after: " is ready.", status: "active",
    likes: 0, dislikes: 0, wins: 0, random: 42, counts: {},
    ...extra,
  };
}

before(async () => {
  const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST ||
      "127.0.0.1:8080").split(":");
  env = await initializeTestEnvironment({
    projectId: "demo-chuckler-rules",
    firestore: {
      host, port: Number(port),
      rules: fs.readFileSync(
          path.join(__dirname, "..", "..", "firestore.rules"), "utf8"),
    },
  });
});

after(async () => {
  if (env) await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed({
    "PromptDays/2026-11-08": {date: new Date()},
    [PROMPT]: {
      before: "My ", after: " is ready.", kind: "fill", location: "global",
      creator: {uid: "chuckler", username: "Chuckler", photoUrl: "",
        kind: "official"},
      counts: {answers: 3, likes: 1}, likedBy: ["bob"],
    },
    "Usernames/bob": {uid: "bob"},
    "Users/alice": {username: "alice"},
    "Users/bob": {username: "bob"},
    "Users/chuckler": {username: "Chuckler", kind: "official"},
    "Users/alice/FriendView/profile": {bio: "hi", stats: {answers: 1}},
    "Users/alice/Private/account": {age: 30},
    "Users/alice/History/2026-11": {answers: {}},
    "Posts/bobs": newPost("bob"),
  });
});

describe("prompts", () => {
  it("signed-in users can read prompt days and prompts", async () => {
    await assertSucceeds(getDoc(doc(as("alice"), "PromptDays/2026-11-08")));
    await assertSucceeds(getDoc(doc(as("alice"), PROMPT)));
  });

  it("signed-out users can't read prompts", async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, PROMPT)));
  });

  it("nobody can create a prompt or edit its text", async () => {
    await assertFails(setDoc(doc(as("alice"), "PromptDays/2026-11-08/" +
        "Prompts/p2"), {before: "x", after: "y"}));
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {before: "Your "}));
    await assertFails(setDoc(doc(as("alice"), "PromptDays/2026-11-09"),
        {date: new Date()}));
  });
});

describe("prompt likes", () => {
  it("allows liking with your own uid and +1", async () => {
    await assertSucceeds(updateDoc(doc(as("alice"), PROMPT), {
      "likedBy": arrayUnion("alice"),
      "counts.likes": increment(1),
    }));
  });

  it("allows unliking with -1", async () => {
    await assertSucceeds(updateDoc(doc(as("bob"), PROMPT), {
      "likedBy": arrayRemove("bob"),
      "counts.likes": increment(-1),
    }));
  });

  it("refuses liking as someone else", async () => {
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {
      "likedBy": arrayUnion("carol"),
      "counts.likes": increment(1),
    }));
  });

  it("refuses removing someone else's like", async () => {
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {
      "likedBy": arrayRemove("bob"),
      "counts.likes": increment(-1),
    }));
  });

  it("refuses a like without the count, or with the wrong count", async () => {
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {
      likedBy: arrayUnion("alice"),
    }));
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {
      "likedBy": arrayUnion("alice"),
      "counts.likes": increment(2),
    }));
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {
      "counts.likes": increment(1),
    }));
  });

  it("refuses a second like", async () => {
    await assertFails(updateDoc(doc(as("bob"), PROMPT), {
      "likedBy": arrayUnion("bob"),
      "counts.likes": increment(1),
    }));
  });

  it("refuses touching other fields or counts along with a like", async () => {
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {
      "likedBy": arrayUnion("alice"),
      "counts.likes": increment(1),
      "counts.answers": increment(1),
    }));
    await assertFails(updateDoc(doc(as("alice"), PROMPT), {
      "likedBy": arrayUnion("alice"),
      "counts.likes": increment(1),
      "before": "Your ",
    }));
  });
});

describe("usernames", () => {
  it("lets you claim a free name for yourself", async () => {
    await assertSucceeds(setDoc(doc(as("alice"), "Usernames/alice"),
        {uid: "alice"}));
  });

  it("refuses a name that is taken", async () => {
    await assertFails(setDoc(doc(as("alice"), "Usernames/bob"),
        {uid: "alice"}));
  });

  it("refuses the reserved Chuckler name once seeded", async () => {
    await seed({"Usernames/chuckler": {uid: "chuckler"}});
    await assertFails(setDoc(doc(as("alice"), "Usernames/chuckler"),
        {uid: "alice"}));
  });

  it("refuses claiming a name for someone else", async () => {
    await assertFails(setDoc(doc(as("alice"), "Usernames/carol"),
        {uid: "carol"}));
  });

  it("refuses extra fields", async () => {
    await assertFails(setDoc(doc(as("alice"), "Usernames/alice"),
        {uid: "alice", admin: true}));
  });

  it("never allows updating a claim, even your own", async () => {
    await assertFails(updateDoc(doc(as("bob"), "Usernames/bob"),
        {uid: "bob"}));
  });

  it("lets you release only your own name", async () => {
    await assertFails(deleteDoc(doc(as("alice"), "Usernames/bob")));
    await assertSucceeds(deleteDoc(doc(as("bob"), "Usernames/bob")));
  });

  it("lets signed-in users check whether a name is taken", async () => {
    await assertSucceeds(getDoc(doc(as("alice"), "Usernames/bob")));
    await assertSucceeds(getDoc(doc(as("alice"), "Usernames/nobody")));
  });
});

describe("posts", () => {
  it("lets you post as yourself with zero counts", async () => {
    await assertSucceeds(setDoc(doc(as("alice"), "Posts/a1"),
        newPost("alice")));
    await assertSucceeds(setDoc(doc(as("alice"), "Posts/a2"),
        newPost("alice", {counts: {likes: 0, wins: 0}})));
  });

  it("lets you post without counts at all", async () => {
    const post = newPost("alice");
    delete post.counts;
    await assertSucceeds(setDoc(doc(as("alice"), "Posts/a1"), post));
  });

  it("refuses posting as someone else", async () => {
    await assertFails(setDoc(doc(as("alice"), "Posts/a1"), newPost("bob")));
  });

  it("refuses posting signed out", async () => {
    const db = env.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, "Posts/a1"), newPost("alice")));
  });

  it("refuses a new post with non-zero counts", async () => {
    await assertFails(setDoc(doc(as("alice"), "Posts/a1"),
        newPost("alice", {counts: {wins: 5}})));
    await assertFails(setDoc(doc(as("alice"), "Posts/a2"),
        newPost("alice", {wins: 5})));
    await assertFails(setDoc(doc(as("alice"), "Posts/a3"),
        newPost("alice", {likedBy: ["alice"]})));
  });

  it("refuses client changes to counts or the author", async () => {
    await assertFails(updateDoc(doc(as("bob"), "Posts/bobs"),
        {"counts.wins": increment(1)}));
    await assertFails(updateDoc(doc(as("alice"), "Posts/bobs"),
        {"counts.likes": 1}));
    await assertFails(updateDoc(doc(as("bob"), "Posts/bobs"),
        {uid: "alice"}));
  });

  it("still allows the legacy likes/wins bumps", async () => {
    await assertSucceeds(updateDoc(doc(as("alice"), "Posts/bobs"),
        {likes: increment(1)}));
    await assertSucceeds(updateDoc(doc(as("alice"), "Posts/bobs"),
        {wins: increment(1)}));
  });

  it("lets signed-in users read posts and only the author delete", async () => {
    await assertSucceeds(getDoc(doc(as("alice"), "Posts/bobs")));
    await assertFails(deleteDoc(doc(as("alice"), "Posts/bobs")));
    await assertSucceeds(deleteDoc(doc(as("bob"), "Posts/bobs")));
  });
});

describe("user docs", () => {
  it("lets signed-in users read user docs", async () => {
    await assertSucceeds(getDoc(doc(as("bob"), "Users/alice")));
  });

  it("keeps legacy writes open, except official accounts", async () => {
    await assertSucceeds(updateDoc(doc(as("bob"), "Users/alice"),
        {pendingFriends: ["bob"]}));
    await assertFails(updateDoc(doc(as("bob"), "Users/chuckler"),
        {bio: "hacked"}));
  });

  it("FriendView: the owner and friends read, nobody writes", async () => {
    const p = "Users/alice/FriendView/profile";
    await assertSucceeds(getDoc(doc(as("alice"), p)));
    // bob isn't a friend yet; a pending request doesn't count
    await assertFails(getDoc(doc(as("bob"), p)));
    await seed({"Users/alice/FriendRequests/bob": {username: "bob"}});
    await assertFails(getDoc(doc(as("bob"), p)));
    await seed({"Users/alice/Friends/bob": {username: "bob"}});
    await assertSucceeds(getDoc(doc(as("bob"), p)));
    await assertFails(getDoc(doc(as("carol"), p)));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),
        p)));
    await assertFails(updateDoc(doc(as("bob"), p), {"stats.answers": 0}));
    await assertFails(updateDoc(doc(as("alice"), p),
        {"stats.answers": 999}));
    await assertFails(setDoc(doc(as("bob"), "Users/bob/FriendView/profile"),
        {bio: "mine"}));
    await assertFails(deleteDoc(doc(as("alice"), p)));
  });

  it("FriendView: signup may create your own empty profile", async () => {
    const p = "Users/carol/FriendView/profile";
    await assertFails(setDoc(doc(as("bob"), p),
        {bio: "", stats: {answers: 0}}));
    await assertFails(setDoc(doc(as("carol"), p),
        {bio: "", stats: {answers: 5}}));
    await assertFails(setDoc(doc(as("carol"), p), {bio: "", stats:
        {answers: 0}, streak: {days: "1111", current: 4, longest: 4}}));
    await assertFails(setDoc(doc(as("carol"), "Users/carol/FriendView/x"),
        {bio: ""}));
    await assertSucceeds(setDoc(doc(as("carol"), p),
        {bio: "", stats: {answers: 0}}));
  });

  it("signup transaction: username, user, profile, private", async () => {
    const db = as("dave");
    await assertSucceeds(Promise.all([
      setDoc(doc(db, "Usernames/dave"), {uid: "dave"}),
      setDoc(doc(db, "Users/dave"), {username: "Dave", profileImage: "",
        friends: 0, pendingFriends: 0, posts: 0}),
      setDoc(doc(db, "Users/dave/FriendView/profile"),
          {bio: "", stats: {answers: 0}}),
      setDoc(doc(db, "Users/dave/Private/account"), {age: 20}),
    ]));
  });

  it("Private: owner only", async () => {
    const p = "Users/alice/Private/account";
    await assertSucceeds(getDoc(doc(as("alice"), p)));
    await assertSucceeds(updateDoc(doc(as("alice"), p), {age: 31}));
    await assertFails(getDoc(doc(as("bob"), p)));
    await assertFails(updateDoc(doc(as("bob"), p), {age: 99}));
    await assertFails(setDoc(doc(as("bob"), "Users/alice/Private/other"),
        {x: 1}));
  });

  it("History: owner reads and adds, others can't", async () => {
    const p = "Users/alice/History/2026-11";
    await assertSucceeds(getDoc(doc(as("alice"), p)));
    await assertSucceeds(updateDoc(doc(as("alice"), p),
        {"answers.2026-11-08_p1": {postId: "a1", answer: "a goose"}}));
    await assertSucceeds(setDoc(doc(as("alice"), "Users/alice/History/" +
        "2026-12"), {answers: {}}));
    await assertFails(getDoc(doc(as("bob"), p)));
    await assertFails(updateDoc(doc(as("bob"), p),
        {"answers.2026-11-08_p1": {postId: "b1"}}));
    await assertFails(deleteDoc(doc(as("alice"), p)));
  });
});

describe("the app's exact writes and reads", () => {
  it("signup: the registerNewUser transaction", async () => {
    const db = as("erin");
    await assertSucceeds(runTransaction(db, async (tx) => {
      const name = doc(db, "Usernames/erin");
      if ((await tx.get(name)).exists()) throw new Error("taken");
      tx.set(name, {uid: "erin"});
      tx.set(doc(db, "Users/erin"), {username: "Erin", profileImage: "",
        friends: 0, pendingFriends: 0, posts: 0});
      tx.set(doc(db, "Users/erin/FriendView/profile"),
          {bio: "", stats: {answers: 0}});
      tx.set(doc(db, "Users/erin/Private/account"), {age: 22});
    }));
  });

  it("signup: the transaction fails on a taken name", async () => {
    const db = as("erin");
    await assertFails(runTransaction(db, async (tx) => {
      await tx.get(doc(db, "Usernames/bob"));
      tx.set(doc(db, "Usernames/bob"), {uid: "erin"});
    }));
  });

  it("posting: the createPost batch (post + History merge)", async () => {
    const db = as("alice");
    const post = (id, promptId) => {
      const b = writeBatch(db);
      b.set(doc(db, `Posts/${id}`), {
        answer: "a goose", dislikes: 0, likes: 0, wins: 0, uid: "alice",
        username: "alice", promptId, random: 12345,
        promptDateId: "2026-11-08", date: Timestamp.now(),
        before: "My ", after: " is ready.", status: "active",
        counts: {matchups: 0, votes: 0, wins: 0, dislikes: 0},
      });
      b.set(doc(db, "Users/alice/History/2026-12"), {answers: {
        [`2026-11-08_${promptId}`]: {postId: id, promptDateId: "2026-11-08",
          promptId, before: "My ", after: " is ready.", answer: "a goose",
          at: Timestamp.now()},
      }}, {merge: true});
      return b.commit();
    };
    // First answer creates the History doc, the second merges into it.
    await assertSucceeds(post("a1", "p1"));
    await assertSucceeds(post("a2", "p2"));
  });

  it("posting: the legacy incrementNumPosts", async () => {
    await assertSucceeds(updateDoc(doc(as("alice"), "Users/alice"),
        {posts: increment(1)}));
  });

  it("login: today's prompts, History and FriendView", async () => {
    const db = as("alice");
    await assertSucceeds(getDocs(collection(db,
        "PromptDays/2026-11-08/Prompts")));
    await assertSucceeds(getDoc(doc(db, "Users/alice/History/2026-11")));
    await assertSucceeds(getDoc(doc(db, "Users/alice/History/2030-01")));
    await assertSucceeds(getDoc(doc(db, "Users/alice/FriendView/profile")));
  });
});

describe("other collections", () => {
  it("leaves legacy collections open to signed-in users", async () => {
    await assertSucceeds(setDoc(doc(as("alice"), "Comments/c1"), {x: 1}));
    await assertSucceeds(setDoc(doc(as("alice"), "Notifications/n1"),
        {x: 1}));
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, "Comments/c1")));
  });

  it("denies anything not matched", async () => {
    await assertFails(setDoc(doc(as("alice"), "Votes/v1"), {x: 1}));
    await assertFails(setDoc(doc(as("alice"), "Elsewhere/x"), {x: 1}));
    await assertFails(getDoc(doc(as("alice"), "Somewhere/else")));
  });
});

// ---- Slice 2: voting, dislikes, comments ----------------------------------

const MATCHUP = "MatchUps/m1";

/**
 * Seeds a matchup between bob's and carol's posts.
 */
async function seedMatchup() {
  await seed({
    "Posts/carols": newPost("carol"),
    [MATCHUP]: {
      promptDateId: "2026-11-08", promptId: "p1", before: "My ",
      after: " is ready.", segment: "global", scope: "public",
      status: "active", postIds: ["bobs", "carols"],
      answers: [
        {postId: "bobs", answer: "a goose", wins: 0, dislikes: 0},
        {postId: "carols", answer: "a goose", wins: 0, dislikes: 0},
      ],
    },
    [`${MATCHUP}/Private/owners`]: {uids: ["bob", "carol"]},
  });
}

/**
 * A vote doc by `uid` on m1.
 * @param {string} uid
 * @param {object} extra
 * @return {object}
 */
function vote(uid, extra = {}) {
  return {uid, matchupId: "m1", card: 0, type: "win",
    promptDateId: "2026-11-08", at: new Date(), ...extra};
}

/**
 * The app's downvote batch: vote, dislike and the post's count.
 * @param {object} db
 * @param {string} uid
 * @param {number} card
 * @return {Promise}
 */
function downvote(db, uid, card = 0) {
  const postId = card === 0 ? "bobs" : "carols";
  const b = writeBatch(db);
  b.set(doc(db, `Votes/m1_${uid}`), vote(uid, {card, type: "dislike"}));
  b.set(doc(db, `Dislikes/${postId}_${uid}`), {uid, targetId: postId,
    targetType: "post", matchupId: "m1", at: new Date()});
  b.update(doc(db, `Posts/${postId}`), {"counts.dislikes": increment(1)});
  return b.commit();
}

describe("matchups", () => {
  beforeEach(seedMatchup);

  it("signed-in users read matchups but not their owners", async () => {
    await assertSucceeds(getDoc(doc(as("alice"), MATCHUP)));
    await assertFails(getDoc(doc(as("alice"), `${MATCHUP}/Private/owners`)));
    await assertFails(getDoc(doc(as("bob"), `${MATCHUP}/Private/owners`)));
  });

  it("clients can't write matchups", async () => {
    await assertFails(setDoc(doc(as("alice"), "MatchUps/m2"), {x: 1}));
    await assertFails(updateDoc(doc(as("alice"), MATCHUP), {status: "x"}));
  });
});

describe("votes", () => {
  beforeEach(seedMatchup);

  it("allows one win vote as yourself", async () => {
    await assertSucceeds(setDoc(doc(as("alice"), "Votes/m1_alice"),
        vote("alice")));
  });

  it("votes are final", async () => {
    await assertSucceeds(setDoc(doc(as("alice"), "Votes/m1_alice"),
        vote("alice")));
    await assertFails(setDoc(doc(as("alice"), "Votes/m1_alice"),
        vote("alice", {card: 1})));
    await assertFails(updateDoc(doc(as("alice"), "Votes/m1_alice"),
        {card: 1}));
    await assertFails(deleteDoc(doc(as("alice"), "Votes/m1_alice")));
  });

  it("refuses votes as someone else or under the wrong id", async () => {
    await assertFails(setDoc(doc(as("alice"), "Votes/m1_dan"),
        vote("dan")));
    await assertFails(setDoc(doc(as("alice"), "Votes/m1_dan"),
        vote("alice")));
    await assertFails(setDoc(doc(as("alice"), "Votes/m2_alice"),
        vote("alice")));
  });

  it("refuses bad cards, types, days and missing matchups", async () => {
    const db = as("alice");
    await assertFails(setDoc(doc(db, "Votes/m1_alice"), vote("alice",
        {card: 2})));
    await assertFails(setDoc(doc(db, "Votes/m1_alice"), vote("alice",
        {type: "superlike"})));
    await assertFails(setDoc(doc(db, "Votes/m1_alice"), vote("alice",
        {promptDateId: "2026-11-09"})));
    await assertFails(setDoc(doc(db, "Votes/m9_alice"), vote("alice",
        {matchupId: "m9"})));
  });

  it("refuses voting on a matchup with your own answer", async () => {
    await assertFails(setDoc(doc(as("bob"), "Votes/m1_bob"), vote("bob")));
  });

  it("you can read your votes, not others'", async () => {
    await seed({"Votes/m1_alice": vote("alice")});
    await assertSucceeds(getDoc(doc(as("alice"), "Votes/m1_alice")));
    await assertFails(getDoc(doc(as("dan"), "Votes/m1_alice")));
  });
});

describe("dislikes", () => {
  beforeEach(seedMatchup);

  it("allows the app's downvote batch", async () => {
    await assertSucceeds(downvote(as("alice"), "alice", 1));
  });

  it("a downvote vote needs its dislike in the same batch", async () => {
    await assertFails(setDoc(doc(as("alice"), "Votes/m1_alice"),
        vote("alice", {type: "dislike"})));
  });

  it("dislikes once per user", async () => {
    await assertSucceeds(downvote(as("alice"), "alice"));
    const db = as("alice");
    const b = writeBatch(db);
    b.set(doc(db, "Dislikes/bobs_alice"), {uid: "alice", targetId: "bobs",
      targetType: "post", at: new Date()});
    b.update(doc(db, "Posts/bobs"), {"counts.dislikes": increment(1)});
    await assertFails(b.commit());
  });

  it("the count can't move without a new dislike doc", async () => {
    await assertFails(updateDoc(doc(as("alice"), "Posts/bobs"),
        {"counts.dislikes": increment(1)}));
  });

  it("the count moves by exactly 1", async () => {
    const db = as("alice");
    const b = writeBatch(db);
    b.set(doc(db, "Dislikes/bobs_alice"), {uid: "alice", targetId: "bobs",
      targetType: "post", at: new Date()});
    b.update(doc(db, "Posts/bobs"), {"counts.dislikes": increment(5)});
    await assertFails(b.commit());
  });

  it("only the disliker reads a dislike; nobody deletes it", async () => {
    await assertSucceeds(downvote(as("alice"), "alice"));
    await assertSucceeds(getDoc(doc(as("alice"), "Dislikes/bobs_alice")));
    await assertFails(getDoc(doc(as("bob"), "Dislikes/bobs_alice")));
    await assertFails(deleteDoc(doc(as("alice"), "Dislikes/bobs_alice")));
  });

  it("refuses a dislike in someone else's name", async () => {
    await assertFails(setDoc(doc(as("alice"), "Dislikes/bobs_dan"),
        {uid: "dan", targetId: "bobs", targetType: "post", at: new Date()}));
  });
});

describe("comments", () => {
  beforeEach(seedMatchup);

  const PAGE = "Posts/bobs/CommentPages/0";

  /**
   * One comment by `uid`.
   * @param {string} uid
   * @param {object} extra
   * @return {object}
   */
  function comment(uid, extra = {}) {
    return {uid, username: uid, text: "lol", matchupId: "m1",
      at: new Date(), ...extra};
  }

  it("voters can start a page and add to it", async () => {
    await seed({"Votes/m1_alice": vote("alice"), "Votes/m1_dan": vote("dan")});
    await assertSucceeds(setDoc(doc(as("alice"), PAGE),
        {comments: {c1: comment("alice")}, last: "c1"}));
    await assertSucceeds(updateDoc(doc(as("dan"), PAGE),
        {"comments.c2": comment("dan"), "last": "c2"}));
    await assertSucceeds(getDoc(doc(as("eve"), PAGE)));
  });

  it("only voters on a matchup with the answer can comment", async () => {
    await assertFails(setDoc(doc(as("alice"), PAGE),
        {comments: {c1: comment("alice")}, last: "c1"}));
  });

  it("refuses others' names, empty text, or edits", async () => {
    await seed({"Votes/m1_alice": vote("alice"), "Votes/m1_dan": vote("dan"),
      [PAGE]: {comments: {c1: comment("dan")}, last: "c1"}});
    const db = as("alice");
    await assertFails(updateDoc(doc(db, PAGE),
        {"comments.c2": comment("dan"), "last": "c2"}));
    await assertFails(updateDoc(doc(db, PAGE),
        {"comments.c2": comment("alice", {text: ""}), "last": "c2"}));
    await assertFails(updateDoc(doc(db, PAGE),
        {"comments.c1": comment("alice"), "last": "c1"}));
    await assertFails(updateDoc(doc(db, PAGE), {
      "comments.c2": comment("alice"), "comments.c3": comment("alice"),
      "last": "c2"}));
  });
});

// ---- Slice 3: friends ------------------------------------------------------

const crypto = require("crypto");

/**
 * The EmailRequests id for an email: SHA-256 hex of it, lowercased.
 * @param {string} email
 * @return {string}
 */
function emailHash(email) {
  return crypto.createHash("sha256").update(email.trim().toLowerCase())
      .digest("hex");
}

/**
 * A Firestore client signed in as `uid` with an email on the token.
 * @param {string} uid
 * @param {string} email
 * @return {object}
 */
function asWithEmail(uid, email) {
  return env.authenticatedContext(uid, {email}).firestore();
}

/**
 * A request card from `uid`.
 * @param {string} uid
 * @return {object}
 */
function card(uid) {
  return {username: uid, photoUrl: "", sentAt: new Date()};
}

/**
 * A Friends doc about `uid`.
 * @param {string} uid
 * @return {object}
 */
function friendDoc(uid) {
  return {username: uid, photoUrl: "", since: new Date()};
}

/**
 * The accepter's batch: both Friends docs, then the request goes.
 * @param {object} db
 * @param {string} me
 * @param {string} them
 * @param {string} requestPath
 * @return {Promise}
 */
function accept(db, me, them, requestPath) {
  const b = writeBatch(db);
  b.set(doc(db, `Users/${me}/Friends/${them}`), friendDoc(them));
  b.set(doc(db, `Users/${them}/Friends/${me}`), friendDoc(me));
  b.delete(doc(db, requestPath));
  return b.commit();
}

describe("friend requests by username", () => {
  beforeEach(() => seed({"Users/carol": {username: "carol"}}));

  it("allows a request as yourself with your real username", async () => {
    await assertSucceeds(setDoc(
        doc(as("bob"), "Users/alice/FriendRequests/bob"),
        card("bob")));
  });

  it("refuses requests as someone else, with a fake name, or to yourself",
      async () => {
        await assertFails(setDoc(doc(as("bob"),
            "Users/alice/FriendRequests/carol"), card("carol")));
        await assertFails(setDoc(doc(as("bob"),
            "Users/alice/FriendRequests/bob"), card("carol")));
        await assertFails(setDoc(doc(as("bob"),
            "Users/bob/FriendRequests/bob"), card("bob")));
        await assertFails(setDoc(doc(as("bob"),
            "Users/chuckler/FriendRequests/bob"), card("bob")));
        await assertFails(setDoc(doc(as("bob"),
            "Users/nobody/FriendRequests/bob"), card("bob")));
      });

  it("refuses a request when already friends", async () => {
    await seed({"Users/alice/Friends/bob": friendDoc("bob")});
    await assertFails(setDoc(doc(as("bob"), "Users/alice/FriendRequests/bob"),
        card("bob")));
  });

  it("only the recipient reads; recipient or sender deletes", async () => {
    await seed({"Users/alice/FriendRequests/bob": card("bob"),
      "Users/alice/FriendRequests/carol": card("carol")});
    await assertSucceeds(getDoc(doc(as("alice"),
        "Users/alice/FriendRequests/bob")));
    await assertFails(getDoc(doc(as("bob"),
        "Users/alice/FriendRequests/bob")));
    await assertFails(deleteDoc(doc(as("carol"),
        "Users/alice/FriendRequests/bob")));
    await assertSucceeds(deleteDoc(doc(as("bob"),
        "Users/alice/FriendRequests/bob")));
    await assertSucceeds(deleteDoc(doc(as("alice"),
        "Users/alice/FriendRequests/carol")));
  });
});

describe("accepting and removing friends", () => {
  beforeEach(() => seed({"Users/carol": {username: "carol"}}));

  it("accepts a username request in one batch", async () => {
    await seed({"Users/alice/FriendRequests/bob": card("bob")});
    await assertSucceeds(accept(as("alice"), "alice", "bob",
        "Users/alice/FriendRequests/bob"));
    await assertSucceeds(getDoc(doc(as("bob"), "Users/bob/Friends/alice")));
  });

  it("accepts an email request in one batch", async () => {
    const h = emailHash("Alice@Example.com");
    await seed({[`EmailRequests/${h}/From/bob`]: card("bob")});
    await assertSucceeds(accept(asWithEmail("alice", "alice@example.com"),
        "alice", "bob", `EmailRequests/${h}/From/bob`));
  });

  it("refuses making friends without a request", async () => {
    const db = as("alice");
    await assertFails(setDoc(doc(db, "Users/bob/Friends/alice"),
        friendDoc("alice")));
    await assertFails(setDoc(doc(db, "Users/alice/Friends/bob"),
        friendDoc("bob")));
    // a request to someone else doesn't count
    await seed({"Users/carol/FriendRequests/bob": card("bob")});
    await assertFails(setDoc(doc(db, "Users/bob/Friends/alice"),
        friendDoc("alice")));
  });

  it("the sender can't accept their own request", async () => {
    await seed({"Users/alice/FriendRequests/bob": card("bob")});
    await assertFails(setDoc(doc(as("bob"), "Users/alice/Friends/bob"),
        friendDoc("bob")));
    await assertFails(setDoc(doc(as("bob"), "Users/bob/Friends/alice"),
        friendDoc("alice")));
  });

  it("refuses fake names on Friends docs", async () => {
    await seed({"Users/alice/FriendRequests/bob": card("bob")});
    await assertFails(setDoc(doc(as("alice"), "Users/bob/Friends/alice"),
        friendDoc("carol")));
  });

  it("only the owner reads friends; either side unfriends", async () => {
    await seed({"Users/alice/Friends/bob": friendDoc("bob"),
      "Users/bob/Friends/alice": friendDoc("alice")});
    await assertSucceeds(getDoc(doc(as("alice"), "Users/alice/Friends/bob")));
    await assertFails(getDoc(doc(as("carol"), "Users/alice/Friends/bob")));
    await assertFails(deleteDoc(doc(as("carol"), "Users/alice/Friends/bob")));
    await assertSucceeds(deleteDoc(doc(as("bob"), "Users/alice/Friends/bob")));
    await assertSucceeds(deleteDoc(doc(as("bob"), "Users/bob/Friends/alice")));
  });

  it("friends docs can't be edited", async () => {
    await seed({"Users/alice/Friends/bob": friendDoc("bob")});
    await assertFails(updateDoc(doc(as("alice"), "Users/alice/Friends/bob"),
        {username: "x"}));
  });
});

describe("friend requests by email", () => {
  const h = emailHash("alice@example.com");

  it("anyone can send one with their real username", async () => {
    await assertSucceeds(setDoc(doc(as("bob"), `EmailRequests/${h}/From/bob`),
        card("bob")));
    await assertFails(setDoc(doc(as("bob"), `EmailRequests/${h}/From/carol`),
        card("carol")));
    await assertFails(setDoc(doc(as("bob"), `EmailRequests/${h}/From/bob`),
        card("alice")));
  });

  it("not to your own email", async () => {
    await assertFails(setDoc(doc(asWithEmail("alice", "alice@example.com"),
        `EmailRequests/${h}/From/alice`), card("alice")));
  });

  it("only the email's owner reads them; the sender can't", async () => {
    await seed({[`EmailRequests/${h}/From/bob`]: card("bob")});
    await assertSucceeds(getDocs(collection(
        asWithEmail("alice", "ALICE@example.com"), `EmailRequests/${h}/From`)));
    await assertFails(getDoc(doc(asWithEmail("carol", "carol@example.com"),
        `EmailRequests/${h}/From/bob`)));
    await assertFails(getDoc(doc(as("bob"), `EmailRequests/${h}/From/bob`)));
  });

  it("the owner declines and the sender cancels", async () => {
    await seed({[`EmailRequests/${h}/From/bob`]: card("bob"),
      [`EmailRequests/${h}/From/carol`]: card("carol")});
    await assertFails(deleteDoc(doc(asWithEmail("dan", "dan@example.com"),
        `EmailRequests/${h}/From/bob`)));
    await assertSucceeds(deleteDoc(doc(asWithEmail("alice",
        "alice@example.com"), `EmailRequests/${h}/From/bob`)));
    await assertSucceeds(deleteDoc(doc(as("carol"),
        `EmailRequests/${h}/From/carol`)));
  });
});

describe("matchup authors", () => {
  beforeEach(async () => {
    await seedMatchup();
    await seed({[`${MATCHUP}/Authors/names`]: {answers: [
      {username: "bob", photoUrl: ""}, {username: "carol", photoUrl: ""},
    ]}});
  });

  it("hidden until you vote, then readable", async () => {
    await assertFails(getDoc(doc(as("alice"), `${MATCHUP}/Authors/names`)));
    await assertSucceeds(setDoc(doc(as("alice"), "Votes/m1_alice"),
        vote("alice")));
    await assertSucceeds(getDoc(doc(as("alice"), `${MATCHUP}/Authors/names`)));
  });

  it("another matchup's vote doesn't count", async () => {
    await seed({"Votes/m2_alice": vote("alice", {matchupId: "m2"})});
    await assertFails(getDoc(doc(as("alice"), `${MATCHUP}/Authors/names`)));
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, `${MATCHUP}/Authors/names`)));
  });

  it("nobody writes it", async () => {
    await seed({"Votes/m1_alice": vote("alice")});
    await assertFails(setDoc(doc(as("alice"), `${MATCHUP}/Authors/names`),
        {answers: []}));
  });
});

describe("notifications", () => {
  const N = "Users/alice/Notifications/n1";
  beforeEach(async () => {
    await seed({[N]: {type: "award", text: "You earned First Post!",
      at: Timestamp.now(), seen: false}});
  });

  it("the owner reads, marks seen and deletes", async () => {
    await assertSucceeds(getDoc(doc(as("alice"), N)));
    await assertSucceeds(getDocs(
        collection(as("alice"), "Users/alice/Notifications")));
    await assertSucceeds(updateDoc(doc(as("alice"), N), {seen: true}));
    await assertSucceeds(deleteDoc(doc(as("alice"), N)));
  });

  it("the owner can't create one, change its text or unsee it", async () => {
    await assertFails(setDoc(doc(as("alice"), "Users/alice/Notifications/n2"),
        {type: "award", text: "fake", at: Timestamp.now(), seen: false}));
    await assertFails(updateDoc(doc(as("alice"), N), {text: "changed"}));
    await assertFails(updateDoc(doc(as("alice"), N),
        {seen: true, text: "changed"}));
    await seed({[N]: {type: "award", text: "x", seen: true}});
    await assertFails(updateDoc(doc(as("alice"), N), {seen: false}));
  });

  it("nobody else reads or writes them", async () => {
    await assertFails(getDoc(doc(as("bob"), N)));
    await assertFails(getDocs(
        collection(as("bob"), "Users/alice/Notifications")));
    await assertFails(updateDoc(doc(as("bob"), N), {seen: true}));
    await assertFails(deleteDoc(doc(as("bob"), N)));
    await assertFails(setDoc(doc(as("bob"), "Users/alice/Notifications/n3"),
        {type: "friendRequest", text: "hi", seen: false}));
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, N)));
  });
});

describe("friend prompts", () => {
  const today = promptDayId(new Date());
  const FP = `FriendPrompts/alice_${today}`;

  /**
   * The app's new friend prompt by alice.
   * @param {object} extra fields to add or override
   * @return {object}
   */
  function friendPrompt(extra = {}) {
    return {
      before: "My dog's secret job is ", after: ".", kind: "fill",
      dayId: today, createdAt: serverTimestamp(), status: "active",
      creator: {uid: "alice", username: "alice", photoUrl: ""},
      counts: {answers: 0, likes: 0, dislikes: 0}, likedBy: [],
      ...extra,
    };
  }

  it("you can write one for today, once", async () => {
    await assertSucceeds(setDoc(doc(as("alice"), FP), friendPrompt()));
    // a second write to the same day's id is an update: refused
    await assertFails(setDoc(doc(as("alice"), FP), friendPrompt()));
  });

  it("refuses the wrong id, day, creator, audience or counts", async () => {
    const yesterday = addDays(today, -1);
    await assertFails(setDoc(doc(as("alice"), `FriendPrompts/bob_${today}`),
        friendPrompt()));
    await assertFails(setDoc(doc(as("alice"), `FriendPrompts/alice_x`),
        friendPrompt()));
    await assertFails(setDoc(doc(as("alice"),
        `FriendPrompts/alice_${yesterday}`), friendPrompt({dayId: yesterday})));
    await assertFails(setDoc(doc(as("alice"), FP), friendPrompt(
        {creator: {uid: "alice", username: "bob", photoUrl: ""}})));
    await assertFails(setDoc(doc(as("alice"), FP),
        friendPrompt({audience: ["alice", "carol"]})));
    await assertFails(setDoc(doc(as("alice"), FP),
        friendPrompt({counts: {answers: 5, likes: 0, dislikes: 0}})));
    await assertFails(setDoc(doc(as("alice"), FP),
        friendPrompt({before: "", after: ""})));
    await assertFails(setDoc(doc(as("alice"), FP),
        friendPrompt({before: "x".repeat(121)})));
    await assertFails(setDoc(doc(as("alice"), FP),
        friendPrompt({createdAt: new Date(0)})));
    const db = env.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, FP), friendPrompt()));
  });

  describe("once the audience is set", () => {
    beforeEach(async () => {
      await seed({[FP]: {...friendPrompt({createdAt: new Date()}),
        audience: ["alice", "bob"]}});
    });

    it("the audience reads it, others don't", async () => {
      await assertSucceeds(getDoc(doc(as("alice"), FP)));
      await assertSucceeds(getDoc(doc(as("bob"), FP)));
      await assertFails(getDoc(doc(as("carol"), FP)));
      await assertSucceeds(getDocs(query(collection(as("bob"), "FriendPrompts"),
          where("audience", "array-contains", "bob"),
          where("dayId", "==", today))));
      await assertFails(getDocs(query(collection(as("bob"), "FriendPrompts"),
          where("dayId", "==", today))));
    });

    it("the audience can like it; nobody edits or deletes it", async () => {
      await assertSucceeds(updateDoc(doc(as("bob"), FP),
          {"likedBy": arrayUnion("bob"), "counts.likes": increment(1)}));
      await assertFails(updateDoc(doc(as("carol"), FP),
          {"likedBy": arrayUnion("carol"), "counts.likes": increment(1)}));
      await assertFails(updateDoc(doc(as("alice"), FP), {before: "x"}));
      await assertFails(updateDoc(doc(as("alice"), FP),
          {audience: ["alice", "bob", "carol"]}));
      await assertFails(deleteDoc(doc(as("alice"), FP)));
    });

    it("only the audience answers it, on its day", async () => {
      const answer = (uid, extra = {}) => newPost(uid, {
        promptSource: "friends", promptId: `alice_${today}`,
        promptDateId: today, ...extra});
      await assertSucceeds(setDoc(doc(as("bob"), "Posts/fb"), answer("bob")));
      await assertFails(setDoc(doc(as("carol"), "Posts/fc"), answer("carol")));
      await assertFails(setDoc(doc(as("bob"), "Posts/fb2"),
          answer("bob", {promptDateId: addDays(today, -1)})));
    });
  });

  describe("friends matchups", () => {
    const FM = "MatchUps/fm";
    beforeEach(async () => {
      await seedMatchup(); // a public one
      await seed({
        [FM]: {promptDateId: today, promptId: `alice_${today}`,
          scope: "friends", audience: ["alice", "bob", "carol"],
          createdAt: new Date(), status: "active",
          postIds: ["bobs", "carols"], answers: [
            {postId: "bobs", answer: "x", wins: 0, dislikes: 0},
            {postId: "carols", answer: "y", wins: 0, dislikes: 0}]},
        [`${FM}/Private/owners`]: {uids: ["bob", "carol"]},
        "MatchUps/pub": {promptDateId: today, scope: "public",
          createdAt: new Date(), postIds: ["bobs", "carols"], answers: []},
      });
    });

    it("only the audience reads them", async () => {
      await assertSucceeds(getDoc(doc(as("alice"), FM)));
      await assertFails(getDoc(doc(as("dave"), FM)));
      await assertSucceeds(getDoc(doc(as("dave"), MATCHUP)));
    });

    it("a matchup without a scope is hidden until migrated", async () => {
      await seed({"MatchUps/old": {promptDateId: today, answers: []}});
      await assertFails(getDoc(doc(as("dave"), "MatchUps/old")));
    });

    it("Home's two queries are allowed; an unscoped one isn't", async () => {
      const db = as("dave");
      await assertSucceeds(getDocs(query(collection(db, "MatchUps"),
          where("scope", "==", "public"), where("promptDateId", "==", today),
          orderBy("createdAt"))));
      await assertSucceeds(getDocs(query(collection(as("alice"), "MatchUps"),
          where("audience", "array-contains", "alice"),
          where("promptDateId", "==", today), orderBy("createdAt"))));
      await assertFails(getDocs(query(collection(db, "MatchUps"),
          where("promptDateId", "==", today), orderBy("createdAt"))));
    });

    it("only the audience votes on them", async () => {
      const v = (uid) => ({uid, matchupId: "fm", card: 0, type: "win",
        promptDateId: today, at: new Date()});
      await assertSucceeds(setDoc(doc(as("alice"), "Votes/fm_alice"),
          v("alice")));
      await assertFails(setDoc(doc(as("dave"), "Votes/fm_dave"), v("dave")));
    });
  });
});
