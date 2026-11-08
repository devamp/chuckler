# Firestore data model

The planned layout for Chuckler's Firestore data, and the reasons behind it. Nothing here is built yet: the app still uses the older layout described under "Today" at the end, and the `TODO(cloud)` notes in `lib/data/` point back here.

## Principles

- **Firestore bills per document read and write**, not per byte or per query. A query returning 20 docs is 20 reads; an empty query is 1. Free tier: 50,000 reads, 20,000 writes and 20,000 deletes per day.
- **Look documents up by id instead of querying.** Day docs are named by date, votes and reactions by `{target}_{uid}`, usernames by the name itself.
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
| Likes and dislikes | On answers and prompts. A downvote in voting **is** a dislike on that answer. |
| Usernames | Can change; a function updates the copies. Limit renames (e.g. once per 30 days). |
| Comments | One thread per answer, for its whole lifetime: it follows the answer through re-pairings and into the Past feed. |
| Comments in voting | Only after you vote. You see the thread of the answer you acted on; tap the other card to see its thread. Only voters can comment. |
| Views | Not counted. Ranking uses votes. |
| Streak history | A string of `1`/`0` per day (see Users). |
| Private account data | Email and password stay in Firebase Auth, never copied to Firestore. |
| **Open:** vote cards | Assumed **anonymous**: matchups don't name their authors, so strangers can't trace answers to people. |
| **Open:** Past feed | Assumed strangers' answers show **without names**; friends' answers show names. |

## Collections

```
Usernames/{username}                  { uid }   one per name; makes names unique

Users/{uid}                           ANYONE: { username, photoUrl }
  FriendView/profile                  FRIENDS + YOU: bio, stats, streak
  Private/account                     YOU: age, notification settings, push tokens, blocked uids
  Friends/{friendUid}                 YOU: { username, photoUrl, since }
  FriendRequests/{fromUid}            YOU: { username, photoUrl, sentAt }
  History/{yyyy-MM}                   FRIENDS + YOU: your answers that month
  Reactions/{yyyy-MM}                 YOU: what you liked and disliked that month
  Notifications/{id}                  YOU

PromptDays/{yyyy-MM-dd}               { date, opensAt, endsAt }
  Prompts/{promptId}                  before, after, segment, counts { answers, likes, dislikes }

Posts/{postId}                        an answer; FRIENDS + YOU (author)
  CommentPages/{n}                    ANY SIGNED-IN USER: ~200 comments per page

MatchUps/{id}                         ANY SIGNED-IN USER: two answers, anonymous
  Private/owners                      SERVER ONLY: which uid wrote each answer

Votes/{matchupId}_{uid}               one per user per matchup; create only
Reactions/{type}_{targetId}_{uid}     one like or dislike per user per answer or prompt
```

### Users

`Users/{uid}` is read constantly (friends lists, comments, username lookups), so it holds only what strangers may see.

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

`Reactions/{yyyy-MM}`: the user's own copy of their likes and dislikes, for the "what I liked" screen:

```
items: { "post_abc": { type, targetId, value: 1 | -1, preview, at } }
```

### Prompts

`PromptDays/{yyyy-MM-dd}`: the date is the doc id, so today's prompts are a direct read.

Friends prompts (user- or AI-created) are not designed yet. A separate collection is likely, so the global daily read stays simple and its read rule ("in the audience") is easier to write.

### Posts (answers)

```
uid, username, photoUrl          copies; updated on rename
promptDateId, promptId, before, after, answer, createdAt
status: "active" | "retired"
matched
counts: { matchups, votes, wins, dislikes, likes, comments }
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
- The `postId` lets the app open an answer's comments, but strangers can't read `Posts/{id}`, so it never leads to the author.
- `preview` copies each answer's latest comments, so the preview after voting costs no reads. When someone comments, a function updates the post and the matchup the answer is currently in (usually one).
- Pair posts in a transaction, so two posts created together can't claim the same unmatched post.

### Votes and reactions

`Votes/{matchupId}_{uid}`: `{ uid, card, type: "win" | "dislike", promptDateId, at }`. Create only; never updated or deleted. Votes are final.

`Reactions/{type}_{targetId}_{uid}`: `{ uid, type: "post" | "prompt", targetId, value: 1 | -1, at }`. Create, update (flip like and dislike) and delete (undo) only your own.

A downvote in voting writes both docs in one batch: the vote, and a dislike on that answer. An answer can be disliked only once, whether in voting or in the Past feed.

## Who writes what

| Action | App writes | Cloud Functions then write |
|---|---|---|
| Sign up | `Usernames/{name}`, `Users/{uid}`, `FriendView/profile`, `Private/account`, in one transaction | |
| Rename | `Usernames/old` deleted, `Usernames/new` created, `Users/{uid}`, in one transaction | the copies in `Posts`, `CommentPages` and friends' `Friends` docs |
| Post an answer | `Posts/{id}` + `History/{month}`, batched | prompt `answers` count, streak and stats (transaction), the matchup |
| Like / dislike | `Reactions/{type}_{id}_{uid}` | target's count, the user's `Reactions/{month}` |
| Vote | `Votes/{id}` (+ the dislike reaction) | the matchup's counts |
| Comment | a key in the latest `CommentPages` doc | post `commentCount` and `preview`, the live matchup's copy |
| Accept a friend | delete the `FriendRequests` doc | `Friends` docs on both sides, both friend counts |

Until the project is on Blaze, functions don't run in production. The app can batch its own `History` write, but counts and streaks stay on sample data, because client-written counts can be edited by anyone.

## Ranking

- A matchup's win rate is wins ÷ (wins + dislikes). No views are counted.
- A matchup needs at least N votes (20 to start) before it's judged.
- Scheduled checkpoint functions total each post's wins and dislikes, cut weak answers, re-pair their opponents and set `rank`. See TODO.md section 4.

## Rules in plain words

- `Users/{uid}`, `CommentPages`, `MatchUps`: any signed-in user can read.
- `FriendView`, `History`, `Posts`: the owner, or a friend. Friendship is "`Users/{them}/Friends/{me}` exists". Each such check inside a rule is billed as one read.
- `Private`, `Reactions/{month}`, `FriendRequests`, `Notifications`, `Friends`: the owner only. `Friends` docs are written only by the server.
- Counts, stats, streaks, ranks and `MatchUps`: the server only.
- `Votes`: create your own, never change.

To verify in the emulator: whether a query on `Posts` (e.g. friends who answered a prompt) is allowed under a rule whose friend check depends on each post's author. If not, the post function keeps a per-prompt list of which friends answered instead.

## A typical session

Assumes 3 prompts, 30 friends, 1 answer posted, 1 prompt liked, 20 votes.

| Step | Reads | Writes |
|---|---|---|
| Open the app (first time today) | 7 | 0 |
| Create tab stats, like a prompt | ~6 | 3 |
| Post an answer | ~2 (functions) | ~7 |
| Vote on 20 matchups, previews included | 20 | ~40 |
| Friends list (cached), a friend's profile, top streaks (cached daily) | ~5 | 0 |
| **Total** | **~25–40** | **~35–50** |

Writes run out before reads on the free tier: roughly 400–570 sessions a day. On Blaze a session costs about $0.0001.

## Today

What the app and the deployed project actually use now:

- `Users/{uid}`: username, age, profileImage, friend and post counts. Readable by any signed-in user, so age is public. Friends are stored by username.
- `PromptDays/{randomId}` with `Prompts/{id}`: found with a date-range query.
- `Posts`: answer, uid, username, promptId, promptDateId, date, random, likes, dislikes, wins, matched.
- `MatchUps`: both answers, uids and usernames, wins1/2, views. Written by `createMatchup`, which is not deployed.
- `Comments`: one doc per comment, keyed by postId.
- Rules: any signed-in user can read and write everything.
- Deployed functions: only `checkUsername` (not in the repo). See CLAUDE.md.
