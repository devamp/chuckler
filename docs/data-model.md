# Firestore data model

The planned layout for Chuckler's Firestore data, and the reasons behind it. Nothing here is built yet: the app still uses the older layout described under "Today" at the end, and the `TODO(cloud)` notes in `lib/data/` point back here.

## Principles

- **Firestore bills per document read and write**, not per byte or per query. A query returning 20 docs is 20 reads; an empty query is 1. Free tier: 50,000 reads, 20,000 writes and 20,000 deletes per day.
- **Look documents up by id instead of querying.** Day docs are named by date, votes by `{matchupId}_{uid}`, usernames by the name itself.
- **Keep counts on the parent document.** Showing "340 answers" reads one prompt doc, never the 340 answers. Cloud Functions keep the counts, so clients can't edit them.
- **Copy what a screen needs into the doc it reads.** A matchup carries both answers and the prompt text, so the voting screen reads one doc per matchup.
- **One doc per action, so rules can stop duplicates.** A second vote on the same matchup is a write to an existing id, which the rules refuse, with no read first.
- **Group many small items into one doc** when they're always read together: a month of a user's answers, a page of ~200 comments.
- **Privacy is per document.** Rules can't hide fields, so anything only friends or only you may see lives in its own doc.

Document limits worth remembering: 1 MiB per doc, 20,000 fields, about one sustained write per second per doc. Subcollections are separate documents: reading a doc never fetches its subcollections, and deleting a doc leaves them behind.

## Decisions

| Decision | Choice |
|---|---|
| Friends | Mutual only (both accept). No followers. |
| What strangers see | Only your username and profile photo. Everything else needs friendship. |
| Likes and dislikes | On answers and prompts. A downvote in voting **is** a dislike on that answer. Likes are stored as liker uids on the answer or prompt itself. **Dislikes are anonymous:** only a count is visible, and nobody (the author included) can see who disliked. The user's own list of what they liked or disliked lives on the phone, not in the cloud. |
| Usernames | Can change; a function updates the copies. Limit renames (e.g. once per 30 days). |
| Comments | One thread per answer, for its whole lifetime: it follows the answer through re-pairings and into the Past feed. |
| Comments in voting | Only after you vote. You see the thread of the answer you acted on; tap the other card to see its thread. Only voters can comment. |
| Views | Not counted. Ranking uses votes. |
| Streak history | A string of `1`/`0` per day (see Users). |
| Prompt days | Roll over at **05:00 UTC** for everyone (midnight Eastern standard time, 10pm Mountain), so friends share the same "today". `lib/data/prompt_day.dart` and `functions/` use the same rule. |
| Prompt format | `kind: "fill"` (fill in the blank). Caption prompts (`kind: "caption"`, with an image) come later. The segment is in `location`; the old data's `type` field held the format. |
| Private account data | Email and password stay in Firebase Auth, never copied to Firestore. |
| Vote cards | **Anonymous**: matchups don't name their authors, so strangers can't trace answers to people. |
| Past feed | Once a prompt ends, its answers show **with usernames**, strangers' included. Voting stays anonymous while the prompt is open. |
| Friend prompts | Users create prompts for their friends from a button on the Create tab. |
| Prompt creator icon | Every prompt shows its creator's profile icon, like any user's. Daily prompts come from an official **Chuckler** account with its own icon and a fun public bio. Sponsors will later be official accounts too, shown with a "Sponsored" label. |

## Collections

```
Usernames/{username}                  { uid }   one per name; makes names unique

Users/{uid}                           ANYONE: { username, photoUrl }
                                      official accounts add: kind, bio (public)
  FriendView/profile                  FRIENDS + YOU: bio, stats, streak
  Private/account                     YOU: age, notification settings, push tokens, blocked uids
  Friends/{friendUid}                 YOU: { username, photoUrl, since }
  FriendRequests/{fromUid}            YOU: { username, photoUrl, sentAt }   sent by username
  History/{yyyy-MM}                   FRIENDS + YOU: your answers that month
  Notifications/{id}                  YOU

PromptDays/{yyyy-MM-dd}               { date, opensAt, endsAt }
  Prompts/{promptId}                  before, after, kind, location, creator, counts { answers, likes, dislikes },
                                      likedBy [uids]
    Results/{n}                       ANY SIGNED-IN USER, after the prompt ends: answers with usernames

FriendPrompts/{promptId}              AUDIENCE: a prompt a user wrote for their friends
  Results/{n}                         AUDIENCE, after the prompt ends

Posts/{postId}                        an answer; FRIENDS + YOU (author)
  CommentPages/{n}                    ANY SIGNED-IN USER: ~200 comments per page

MatchUps/{id}                         ANY SIGNED-IN USER: two answers, anonymous
  Authors/names                       VOTERS ON THIS MATCHUP: who wrote each answer
  Private/owners                      SERVER ONLY: which uid wrote each answer

EmailRequests/{emailHash}/From/{uid}  THAT EMAIL'S OWNER: a friend request sent by email

Votes/{matchupId}_{uid}               one per user per matchup; create only
Dislikes/{targetId}_{uid}             one per user per answer or prompt; readable only by its creator
```

### Users

`Users/{uid}` is read constantly (friends lists, comments, username lookups), so it holds only what strangers may see.

**Official accounts** are `Users` docs too, so they look and behave like anyone else's profile:

```
Users/chuckler      { username: "Chuckler", photoUrl, kind: "official", bio: "…" }
Users/{sponsorId}   { username, photoUrl, kind: "sponsor", bio }          (later)
```

- `kind` is missing (or `"user"`) for normal users. For official and sponsor accounts, `bio` sits on the public doc, since anyone may read it; normal users' bios stay friends-only in `FriendView`.
- Their usernames are reserved in `Usernames`, so nobody can register "chuckler".
- Only the server or an admin writes them. Nobody can sign in as them; they own prompts, not answers.
- Nobody can friend them: tapping their icon opens their public profile.

`FriendView/profile`:

```
bio
stats:  { answers, wins, bestRank, friends }
streak: {
  days:    "1101110001111",   one character per prompt day, oldest first
  from:    "2026-10-27",      the day days[0] stands for
  current: 4,                 stored so leaderboards can sort on it
  longest: 5,
}
```

- Day `from + i` is `days[i]`; the current streak is the run of trailing `1`s.
- Zeros for missed days are appended when the user next answers, in the same write. Readers treat days after the end of the string as missed, and show `current` as 0 if the string ends before yesterday.
- "Today" is the prompt's day (`promptDateId`), not the phone's clock.
- One byte per day: about 3.6 KB for ten years. If it ever grows too large, move old years into History.

`History/{yyyy-MM}`: the user's answers, about 90 a month (~35 KB):

```
answers: {
  "2026-11-08_p1": { postId, promptDateId, promptId, before, after, answer,
                     segment, at, final: { wins, dislikes, rank, winRate } }
}
```

`final` is filled in once, when the prompt's lifetime ends. Live stats while a prompt is open come from `Posts`. Exempt `answers` from indexing in `firestore.indexes.json` (`fieldOverrides`).

### Prompts

`PromptDays/{yyyy-MM-dd}`: the date is the doc id, so today's prompts are a direct read.

Every prompt, daily or friend, names its **creator**, shown on the card as a normal profile icon:

```
creator: { uid, username, photoUrl, kind }
```

- Daily prompts: the Chuckler account (`uid: "chuckler"`, `kind: "official"`).
- Friend prompts: the friend who wrote it. `kind` is absent.
- Sponsored prompts (later): the sponsor's account (`kind: "sponsor"`). The card must show a visible "Sponsored" label.

The username and photo are copied into the prompt, so the card costs no extra reads; a rename updates the copy. Tapping the icon opens the creator's profile: a friend's full profile, or an official account's public one with its bio.

### Friend prompts

```
FriendPrompts/{promptId}
  before, after, createdAt, opensAt, endsAt
  creator: { uid, username, photoUrl }
  audience: [uids]              the creator + their friends when the prompt was made
                                (open: or a group the creator picks; see TODO.md)
  status: "active" | "ended" | "removed"
  counts: { answers, likes, dislikes }, likedBy: [uids]
```

- **A separate collection, not `PromptDays`,** so the daily read stays one direct lookup, and the read rule is simply "your uid is in `audience`".
- **Finding yours:** `FriendPrompts where audience array-contains me and status == "active"`. That's one read per active friend prompt, and the rule can approve it because the query itself asks for `audience` containing you.
- **The audience is set by the server.** Rules can't cheaply check that every uid in a list is your friend (each check is a read, and rules allow only a handful per request). So the app writes the prompt without an audience, and a function fills it in from the creator's `Friends`. Until Blaze, a friend prompt can't reach anyone.
- **Answers are normal `Posts`**, with `promptSource: "friends"` and `promptId` pointing here. Their matchups copy `audience`, so only the audience can read them. With a small audience, anonymous voting is thin cover; that's accepted.
- **Limits:** cap prompts per user per day (1 to start) to control spam and cost. Friend prompts need report and block (App Store guideline 1.2), the same as answers and comments.
- **A creator snapshot:** the creator's username and photo are copied into `creator`; a rename updates them.

### Past results

When a prompt ends, the checkpoint function writes its answers, best first, into `Results/{n}` under the prompt (about 100 per page):

```
answers: [ { postId, uid, username, photoUrl, answer, wins, dislikes, winRate, rank }, … ]
```

- **The Past feed reads one page per prompt** instead of one doc per answer. Comments still come from `Posts/{postId}/CommentPages`, which anyone can read.
- **`Posts` stay friends-only.** Results are a public copy of finished answers only, so live stats and a user's other answers stay private.
- Daily prompts' results are readable by any signed-in user; friend prompts' results only by their audience.

### Posts (answers)

```
uid, username, photoUrl          copies; updated on rename
promptDateId, promptId, before, after, answer, date          (named date, not createdAt, so getPosts keeps working)
status: "active" | "retired"
matched
counts: { matchups, votes, wins, dislikes, likes, comments }
likedBy [uids]
winsByHour, rank
commentCount, preview: [latest 2 comments]
```

Wins, dislikes and rank are totalled at checkpoints (see Ranking), not on every vote.

`CommentPages/{n}`:

```
comments: { "c8f2": { uid, username, text, matchupId, at }, … }
```

- About 200 comments per page (~60 KB). When a page fills, start the next one.
- A thread of 50 comments is 1 read instead of 50.
- Rules allow adding exactly one key carrying your own uid, and removing only your own key. They require that `Votes/{matchupId}_{uid}` exists and that the matchup contains this post, so only voters comment.
- `matchupId` is stored so the rule can check the vote.

### MatchUps

```
promptDateId, promptId, before, after, segment, createdAt, status, score
answers: [
  { postId, answer, wins, dislikes, commentCount, preview: [latest 2] },
  { postId, … },
]
```

- No uids or usernames, so voting is anonymous and renames never touch matchups. `Private/owners` holds the uids for the server (pairing, notifications).
- **Authors are revealed after you vote.** `Authors/names` (`answers: [{username, photoUrl}, …]`, card order) is written by `createMatchup` and readable only when `Votes/{matchupId}_{you}` exists, so the cards show both authors once your vote (win or downvote) is saved. One read per vote.
- The `postId` lets the app open an answer's comments, but strangers can't read `Posts/{id}`, so it never leads to the author.
- `preview` copies each answer's latest comments, so the preview after voting costs no reads. When someone comments, a function updates the post and the matchup the answer is currently in (usually one).
- Pair posts in a transaction, so two posts created together can't claim the same unmatched post.

### Votes

`Votes/{matchupId}_{uid}`: `{ uid, card, type: "win" | "dislike", promptDateId, at }`. Create only; never updated or deleted. Votes are final.

A downvote in voting writes, in one batch, the vote and an anonymous dislike on that answer (see below). An answer can be disliked only once, whether in voting or in the Past feed.

### Likes

Posts and prompts store who liked them:

```
likedBy: [uid, uid, …]
counts:  { likes, dislikes }
```

- **One write per like.** The app adds its uid with `arrayUnion` (or removes it with `arrayRemove`) and updates the count in the same write. `arrayUnion` ignores duplicates, so a double tap can't like twice.
- **No Cloud Function needed, so it works on Spark.** The rules check that the write changed only `likedBy` and `counts.likes`, added or removed only the writer's own uid, and set the count to the size of the list.
- **"Did I like this?"** is a lookup in a doc the screen has already read: no extra read.
- **The user's own list of what they liked** is kept on the phone (Isar). It doesn't survive a reinstall or a new phone; for prompts, a `likedBy array-contains me` query can rebuild it. For answers it can't, because strangers' answers aren't readable.
- **Size:** each uid is about 30 bytes, so a doc holds roughly 30,000 likers before the 1 MiB limit, and every read of the doc downloads the whole list. Far off at this scale. If an answer or prompt ever gets that popular, move its liker uids into a subcollection and keep only the count on the doc.
- **Who can see likers:** anyone who can read the doc. For prompts that's every signed-in user, but a uid only leads to a username and photo, which are public anyway.
- **Update limit:** about one write per second per doc. Not a concern at this scale.

### Dislikes (anonymous)

A dislike can't be a uid on the post: the author can read their own post, so they would see who disliked them. Hashing uids wouldn't help either, since the author could hash their friends' uids and compare. Instead:

```
Dislikes/{targetId}_{uid}     { uid, targetType: "post" | "prompt", at }
                              readable only by uid; never by the author
```

To dislike, the app writes one batch:
1. create `Dislikes/{postId}_{me}`
2. add 1 to the post's `counts.dislikes`

- **Once per person.** The doc id is fixed, so a second dislike would be a write to an existing doc, which the rules refuse.
- **No Cloud Function needed.** The rule on the post allows `counts.dislikes` to go up by exactly 1 only when the same batch creates that user's `Dislikes` doc (`existsAfter`) and it didn't exist before (`exists`). Undoing deletes the doc and subtracts 1 under the same kind of check.
- **The author sees only the count.** Nobody can query other people's `Dislikes` docs.
- **Votes are final, so dislikes from voting can't be undone.** The rules refuse deleting a `Dislikes` doc while a `Votes` doc with type `dislike` exists for that answer (the dislike stores the `matchupId` it came from).
- **Cost:** 2 writes per dislike, 0 reads. Liking a post you've disliked is refused by the rules (or the app first undoes the dislike).

## Who writes what

| Action | App writes | Cloud Functions then write |
|---|---|---|
| Sign up | `Usernames/{name}`, `Users/{uid}`, `FriendView/profile`, `Private/account`, in one transaction | |
| Rename | `Usernames/old` deleted, `Usernames/new` created, `Users/{uid}`, in one transaction | the copies in `Posts`, `CommentPages`, `Results`, prompt `creator` copies and friends' `Friends` docs |
| Post an answer | `Posts/{id}` + `History/{month}`, batched | prompt `answers` count, streak and stats (transaction), the matchup |
| Like | uid into `likedBy` + the count, one write | nothing |
| Dislike | `Dislikes/{id}_{uid}` + the count, one batch (2 writes) | nothing |
| Vote | `Votes/{id}` (+ the anonymous dislike for a downvote) | the matchup's counts |
| Comment | a key in the latest `CommentPages` doc | post `commentCount` and `preview`, the live matchup's copy |
| Send a friend request | `FriendRequests/{me}` under them (by username), or `EmailRequests/{hash}/From/{me}` (by email) | |
| Accept a friend | `Friends` docs on both sides + delete the request, one batch | |
| Create a friend prompt | `FriendPrompts/{id}` (before, after, creator, no audience) | `audience` from the creator's friends |
| A prompt ends | | its `Results` pages, `final` stats in each author's `History` |

Until the project is on Blaze, functions don't run in production. The app can batch its own `History` write, but counts and streaks stay on sample data, because client-written counts can be edited by anyone.

## Ranking

- A matchup's win rate is wins ÷ (wins + dislikes). No views are counted.
- A matchup needs at least N votes (20 to start) before it's judged.
- Scheduled checkpoint functions total each post's wins and dislikes, cut weak answers, re-pair their opponents and set `rank`. See TODO.md section 4.

## Rules in plain words

- `Users/{uid}`, `CommentPages`, daily `MatchUps`, daily `Results`: any signed-in user can read.
- `FriendPrompts`, their `Results`, and matchups for friend prompts: only uids in `audience`. The creator can create a friend prompt with themselves as `creator` and no `audience`, and can end or remove it; nobody else writes it.
- `FriendView`, `History`, `Posts`: the owner, or a friend. Friendship is "`Users/{them}/Friends/{me}` exists". Each such check inside a rule is billed as one read.
- `Private`, `FriendRequests`, `Notifications`, `Friends`: the owner only. A `Friends` doc about you can be written into someone else's list only while they have a request from you waiting (the accepter's batch). Either side can delete (unfriend).
- `EmailRequests/{hash}`: only the user whose own email hashes to `hash` can read or decline; anyone can send one under their own uid.
- Counts, stats, streaks, ranks and `MatchUps`: the server only, except `likedBy`, `counts.likes` and `counts.dislikes`, which signed-in users may change only as described under Likes and Dislikes. Updating them doesn't require being able to read the doc, so strangers can dislike anonymous answers.
- `Dislikes/{id}_{uid}`: only that uid can read, create or delete it.
- `Votes`: create your own, never change.

To verify in the emulator: whether a query on `Posts` (e.g. friends who answered a prompt) is allowed under a rule whose friend check depends on each post's author. If not, the post function keeps a per-prompt list of which friends answered instead.

## A typical session

Assumes 3 prompts, 30 friends, 1 answer posted, 1 prompt liked, 20 votes.

| Step | Reads | Writes |
|---|---|---|
| Open the app (first time today) | 7 | 0 |
| Create tab stats, like a prompt | ~6 | 1 |
| Post an answer | ~2 (functions) | ~7 |
| Vote on 20 matchups (5 dislikes), previews included | 20 | ~50 |
| Friends list (cached), a friend's profile, top streaks (cached daily) | ~5 | 0 |
| **Total** | **~25–40** | **~55** |

Each vote is the `Votes` doc plus the function's matchup count; a downvote adds 2 writes (the `Dislikes` doc and the count). Writes run out before reads on the free tier: roughly 360 sessions a day. On Blaze a session costs about $0.0001.

## Live in the emulator

Slice 1 (the Create tab) runs on this layout in the local emulator:
- `PromptDays/{dayId}/Prompts`: read directly by day id (N reads, no query), with `kind`, `location`, `creator`, `counts`, `likedBy`. Liking is live.
- `Posts` (with `before`, `after`, `status`, `counts`) and `Users/{uid}/History/{yyyy-MM}`, written in one batch. Login reads today's answers from one History doc.
- `Users/{uid}/FriendView/profile` (stats, streak string, kept by the `onPostCreated` function) and `Private/account` (age).
- `Usernames`, claimed in a transaction at signup.
- `Users/{uid}` still carries the legacy fields (friend lists by username, post count) until the friends slice.

Slice 2 (Home voting and answer comments):
- `MatchUps`, written by `createMatchup` in a transaction (no two posts claim the same partner), with `Private/owners` for the authors' uids. Matchups also carry `postIds` (the two post ids), which the comment rule and the comment function look up. The app reads today's matchups by `promptDateId` ordered by `createdAt`, and leaves out its own answers (known from History) and matchups it already voted on.
- `Votes/{matchupId}_{uid}`, create only. A downvote is one batch with `Dislikes/{postId}_{uid}` and the post's `counts.dislikes`. Rules refuse voting on a matchup with your own answer.
- `onVoteCreated` counts the vote on the matchup's answer. Until ranking checkpoints exist it also adds to the posts' `counts.votes` and `counts.wins` (and `createMatchup` to `counts.matchups`), so the Create tab's answer stats are live; `rank` stays 0.
- `Posts/{postId}/CommentPages/{n}` (pages "0", "1", …) with a `last` field naming the comment just added, which the rule checks. `onCommentPageWritten` keeps `commentCount` and `preview` on the post and its active matchups.

Slice 3 (friends):
- Mutual friends by uid: `Users/{uid}/Friends/{friendUid}` on both sides, written by the accepter in one batch with the request's deletion. The rules allow it only while the request exists, so no Cloud Function is needed (works on Spark). The friend count is a `count()` query; nothing is stored.
- Requests by username: `Users/{them}/FriendRequests/{me}`, after looking the name up in `Usernames`.
- Requests by email: `EmailRequests/{emailHash}/From/{me}`. `emailHash` is SHA-256 hex of the trimmed, lowercased address; the rules compute the same from the signed-in user's token (`hashing.sha256`), so only that email's owner reads them. The sender learns nothing about whether the email has an account, and the database never stores addresses.
- Uids never appear in the UI: people search by username or email.

- Friends who answered (Create tab): per prompt, `Posts` where `promptDateId`, `promptId` and `uid in` the user's friends, 30 uids per query; one read per answer found. Works because `Posts` are still readable by any signed-in user; once they become friends-only, the rule's friend check must allow this query.

Not live yet: ranking and checkpoints, friend streak standings, friend profiles, friend prompts, Past results, prompt dislikes, undoing a dislike.

## Before the new layout

What production and the old app used:

- `Users/{uid}`: username, age, profileImage, friend and post counts. Readable by any signed-in user, so age is public. Friends are stored by username.
- `PromptDays/{randomId}` with `Prompts/{id}`: found with a date-range query.
- `Posts`: answer, uid, username, promptId, promptDateId, date, random, likes, dislikes, wins, matched.
- `MatchUps`: both answers, uids and usernames, wins1/2, views. Written by `createMatchup`, which is not deployed.
- `Comments`: one doc per comment, keyed by postId.
- Rules: any signed-in user can read and write everything.
- Deployed functions: only `checkUsername` (not in the repo). See CLAUDE.md.
