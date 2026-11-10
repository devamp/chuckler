# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Chuckler is a Flutter social party game: users answer a daily fill-in-the-blank prompt, and the answers are paired into head-to-head "matchups" that other users vote on. Backend is Firebase (Auth, Firestore, Storage, Cloud Functions), project `chuckler-622ff`. iOS is the main target. The iOS project uses Swift Package Manager and the UIScene lifecycle, with a minimum of iOS 15.

## Commands

```bash
flutter pub get
flutter analyze                         # lints: flutter_lints + analysis_options.yaml
flutter test                            # all tests
flutter test test/data/posts_test.dart  # single file
flutter test --plain-name "<name>"      # single test by name

# Regenerate Isar code after editing lib/database/models.dart
dart run build_runner build             # --delete-conflicting-outputs is ignored by build_runner 2.16+

# Develop against local emulators (the normal way)
flutter run --dart-define=USE_EMULATOR=true
# Physical iPhone: point it at the Mac's LAN IP (`ipconfig getifaddr en0`), not
# 127.0.0.1, which on the phone means the phone. The emulators listen on all
# interfaces (firebase.json), and Info.plist allows local-network HTTP.
flutter run --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.1.x
# Without the flag the app talks to PRODUCTION Firebase
flutter run
```

Firebase emulators (auth 9099, firestore 8080, functions 5001, storage 9199, UI enabled). Seed data is in `fb_em_data/`: the Chuckler account, eight test accounts (`ava`, `ben`, `cleo`, `dev`, `eli`, `fay`, `gus`, `hal` `@chuckler.test`, password in `functions/scripts/seed.js`; ava, ben and cleo are friends, and ava has a username request from dev and an email request from eli), prompt days around the day it was made, and every test account's answers to that day's and the previous day's prompts, paired into matchups by `createMatchup`, with the previous day's results finished. Run the seed on fresh emulators with functions running, then export:

```bash
firebase emulators:start --import=fb_em_data [--export-on-exit=fb_em_data]

# Refresh the seed when its prompt days have passed (emulators running):
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm --prefix functions run seed
firebase emulators:export fb_em_data
```

Cloud Functions (`functions/`, Node 20, ESLint google config; lint runs as a predeploy step). `firebase-functions` is pinned to 5.0.1 because the installed Firebase CLI (13.15) rejects the build spec of 5.1+ ("Unexpected key extensions"); upgrade the CLI before upgrading the SDK.

```bash
cd functions && npm install && npm run lint
# Rules tests (functions/test/rules.test.js) against the Firestore emulator:
firebase emulators:exec --only firestore "npm --prefix functions test"
npm run deploy        # firebase deploy --only functions
```

Emulator mode is opt-in only, through `USE_EMULATOR`. Never hardcode emulator calls into `lib/main.dart`. Builds without the flag must hit production. In emulator mode the Firestore offline cache is off, since emulator data is reset often and a cached copy from an earlier run shows stale data.

Tests run without Firebase: `test/data/` covers the query functions against `fake_cloud_firestore` (shared fixtures in `test/data/helpers.dart`), and `test/state/` covers the ChangeNotifier services. They are characterization tests: they describe current behavior, and suspected bugs are matched as-is and marked `TODO(bug)` rather than fixed. `test/widgets/` renders individual screens with fake services at iPhone sizes (`test/widgets/fonts.dart` loads the real fonts for overflow checks); `MyApp` itself is not tested, because it needs Firebase and Isar to start.

## Architecture

**Startup (`lib/main.dart`)**: opens the Isar DB, initializes Firebase (`lib/firebase/firebase_options.dart`), optionally connects the emulators, then wraps `MyApp` in a `MultiProvider` that supplies:
- `ChangeNotifier`s in `lib/state/`:
  - `SessionService`: the logged-in `DbUser`, last login time and `firstLogin`.
  - `PromptService`: today's prompts and the user's post for each one; `logout()` clears these (and only these).
  - `FeedService`: feed posts, the current feed prompt id, and the viewing post/color.
  - `VotingService`: the Home tab's swipe-voting queue, the user's votes and the back history.
  - `AccountService`: the Account tab's profile stats and awards, answers and notifications.
  - `LeaderboardService`: the Leaderboard tab's scope, board, period and loaded boards.
  - `CreateService`: the Create tab's prompt pages (live prompts, plus sample prompts in debug builds when none is live), the user's answer or draft per prompt, per-prompt stats and the answer streak.
  Screens look up only the services they read, e.g. `Provider.of<SessionService>(context, listen: false)`.
- `IsarService` (`lib/database/isarDB.dart`), the local on-device cache.
- `FirebaseFirestore.instance`, injected so query functions receive it as a parameter.

**Navigation**: `lib/route_generator.dart` has the named routes `/` (login), `/signup`, `/app`. `/app` opens `NavigationBarController` (`lib/AppNavBar.dart`), a bottom-nav shell that swaps between pages in `lib/pages/` (create, feed, leaderboard, account, ...) by index rather than with routes.

**Data layer: two tiers**
- Remote: `lib/data/` holds top-level async Firestore functions grouped by feature: `prompts.dart`, `posts.dart`, `users.dart`, `friends.dart`, `comments.dart`. Each takes a `FirebaseFirestore` argument. Firestore collections: `Users` (with subcollections such as `FriendView`, `History`, `Friends`, `Notifications`), `Posts`, `Comments`, `PromptDays`, `MatchUps`, `Votes`, `Dislikes`, `EmailRequests`, `Usernames`.
- Settings (`lib/pages/accountpage/settings.dart`): account details, Change password (reset email), Hidden prompts, About (version; Contact/Terms/Privacy rows appear once `supportEmail`, `termsUrl`, `privacyUrl` in `constant_strings.dart` are set), Log out and Delete account (re-enter password, then `user.delete()`; `onAccountDeleted` cleans up). Both go through `signOut` in `lib/state/sign_out.dart`, which returns to `/` and then clears every service and the Isar cache. Widget tests use `firebase_auth_mocks`.
- Moderation is live (`lib/data/moderation.dart`, `ModerationService`, `lib/CustomReusableWidgets/moderation_sheets.dart`; server `functions/moderation.js` with `onReportCreated` and `onBlockCreated`): hold an answer, prompt, comment or person to Report or Block. `VotingService.exclude` and the comment, Create and Leaderboard screens ask `ModerationService` what to hide. `functions/wordlist.json` (categories) blocks words in usernames and drives the per-user Settings > Content filter. Review reports in the console (`Reports`, `Moderation`).
- Users can hide a prompt from Home by holding it (`Users/{uid}/Private/hiddenPrompts`, today's only; `VotingService.hidePrompt`). It doesn't affect the Create tab.
- Home voting is live on the new layout (`docs/data-model.md`, "Live in the emulator", slice 2): `lib/data/matchups.dart` reads today's `MatchUps` and writes `Votes` (plus an anonymous `Dislikes` doc for a downvote); `lib/data/comments.dart` reads and adds answer comments in `Posts/{id}/CommentPages`. `sample_matchups.dart` is only for tests.
- Friends are live too (slice 3): `lib/data/friends.dart` sends requests by username (`Users/{them}/FriendRequests/{me}`) or email (`EmailRequests/{sha256(email)}/From/{me}`, readable only by that email's owner), and accepting writes both `Users/{uid}/Friends` docs in one batch. `FriendsService` backs the Friends screen (`lib/pages/friends/`), opened from the Account tab's Friends count. Uids are internal: the UI only shows usernames.
- The Leaderboard tab is live (`lib/pages/leaderboardpage/`, `LeaderboardService`, `lib/data/leaderboards.dart`): Friends boards are computed in the app from friends' `FriendView/profile` (stats, `week`, streak) and History; Global boards read the server's daily `Leaderboards` snapshot. Weeks start Monday (`weekStartId`); `applyStats` keeps `week` and `weekPrev`.
- Friend prompts are live (`lib/data/friend_prompts.dart`): `FriendPrompts/{uid}_{dayId}`, one per user per prompt day, shown on the Create tab after the daily prompts. `isFriendPrompt` (DbPrompt.type == 'friend') routes stats, likes and posting to them; `promptRef` in `prompt_stats.dart` picks the right doc.
- The Account tab is live: `AccountService` (`lib/state/account_service.dart`) reads `FriendView/profile` (stats, streak, awards), the user's History months and `Users/{uid}/Notifications` through `lib/data/account.dart`. Awards come from `functions/awards.json`, shared with the functions and bundled as an asset; `lib/data/awards.dart` parses it. Add award tiers there, not in Dart.
- The Create tab is live on the new layout (`docs/data-model.md`, "Live in the emulator"). Prompt days roll over at 05:00 UTC (`lib/data/prompt_day.dart`); `getDailyPrompts` reads `PromptDays/{dayId}/Prompts`; `createPost` batches the post with the user's `History/{yyyy-MM}` entry; login reads today's answers from History; signup (`registerNewUser` in `lib/data/users.dart`) claims `Usernames/{name}` in a transaction. `lib/data/prompt_stats.dart` reads prompt counts, likes and the streak; sample stats are used only for the sample prompts debug builds add when no real prompt is live. Answers to sample prompts stay on the phone.
- When today has no prompt, `getDailyPrompts` returns a placeholder prompt (`awaitingPrompt()`, checked with `isAwaitingPrompt`). It has a null date so the Isar cache never serves it, and the create page refuses to post to it.
- Local: Isar (the community fork, `isar_community` 3.4.x, which supports Swift Package Manager) models in `lib/database/models.dart` (`DbPost`, `DbPrompt`, `DbUser`, `DbComment`, `DbNotification`). `models.g.dart` is generated, so don't hand-edit it. Fetched Firestore data is mapped into these models, cached in Isar, and pushed into the `lib/state/` services for the UI.
- `lib/db.dart` is an older SharedPreferences-based store, still used by the login flow for things like caching the last login time.

**Server-side logic (`functions/index.js`)**: Firestore triggers:
- `createMatchup` (Posts created) pairs the new post with the oldest unmatched post for the same `promptId` + `promptDateId` in a transaction and writes an anonymous `MatchUps` doc (authors in `Private/owners`), or marks the post `matched: false`.
- `onPostCreated` bumps the prompt's `counts.answers` and, in a transaction, the author's `FriendView/profile` `stats.answers` and streak string (`functions/promptDay.js`, the JS twin of `lib/data/prompt_day.dart`).
- `onVoteCreated` (Votes created) counts the vote on the matchup and the two posts.
- `onCommentPageWritten` keeps an answer's `commentCount` and `preview` on the post and its matchups, counts the writer's `stats.comments` and notifies the answer's author.
- `onFriendRequestCreated` and `onFriendWritten` notify about friend requests (by username) and new friends; `onFriendWritten` keeps `stats.friends`.
- `onFriendPromptCreated` sets a friend prompt's `audience` (the creator and their friends) and notifies the friends. `createMatchup` gives matchups for friend prompts (posts with `promptSource: "friends"`) `scope: "friends"` and the audience; daily ones get `scope: "public"`. The rules let only the audience read friends matchups, so every matchup query must filter on `scope` or `audience` (`getVotingMatchups` runs both). Older matchups need `npm --prefix functions run migrate`.
- Stats changes go through `applyStats` in `functions/profile.js`, which awards any tier reached (`functions/awards.js`) and writes an award notification. `onVoteCreated` adds the winner's `stats.wins`.
- `onAccountDeleted` (v1 auth trigger) runs `deleteUserData` (`functions/account.js`) when an Auth user is deleted: their Users tree, username claim, friends' list entries, sent requests, posts with their matchups, friend prompts, votes, dislikes, comments and leaderboard rows.
- `dailyResults` (scheduled 05:05 UTC) runs `finishDay` (`functions/results.js`): final stats into History, a results notification per author, and the global `Leaderboards/{board}` snapshot (`functions/leaderboards.js`). The emulator doesn't run schedules: `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 npm --prefix functions run finish-day [-- yyyy-MM-dd]` (default yesterday). `npm --prefix functions run recount` recomputes everyone's stats, weekly counts and awards; `run leaderboards [-- day]` rewrites just the boards; `run seed:votes` has the test accounts vote on yesterday's matchups (then recount and `finish-day -- --force`).
Matchups exist only because of these triggers. The Past feed is hidden for the first release (`showPastToggle` in `feed_page.dart`) and still built from `Posts` via `getPosts`.

**Rules/config**: `firestore.rules`, `storage.rules`, `firestore.indexes.json`, all wired up in `firebase.json`. `firestore.rules` has explicit rules for the slice-1 and slice-2 collections (prompts and likes, usernames, FriendView, Private, History, Notifications, new posts, MatchUps, Votes, Dislikes, CommentPages, friends) and leaves the legacy collections open to signed-in users; anything else is denied.

**UI conventions**: shared widgets live in `lib/CustomReusableWidgets/`. The theme is in `lib/Theme/theme.dart` (dark theme only), with custom fonts OpenSans, Livvic and NewAmsterdam. Shared copy is in `lib/pages/constant_strings.dart`.

## Working agreements

- Work on the `revive` branch. Never run `git push`; the user reviews and pushes.
- iOS first. The Android build is not set up yet.
- Use plan mode before large changes: changing the local database, editing Firestore/Storage rules, changing the bundle ID.

## Firebase safety

- Production (`chuckler-622ff`) holds only test accounts for now. It is on the free Spark plan, so Cloud Functions (which need Blaze) do not run there; moving to Blaze makes it billed.
- Develop against the emulator by default (`--dart-define=USE_EMULATOR=true`).
- Never deploy functions or rules, or write to production, without asking first (cost control).

## Known follow-ups

Planned features and design decisions (prompt types, Create-tab swiping, Home swipe voting, past responses feed, prompt lifetimes) are in `TODO.md`. The planned Firestore layout (collections, rules, who writes what, read/write costs) is in `docs/data-model.md`; the current layout is summarized at its end.

- Deployed functions don't match the repo (checked 2026-11-08 with `firebase functions:list`). Production has only `checkUsername`, a v1 callable on Node 18 whose source was never committed. `createMatchup` and `incrementPrompt` have never been deployed, so production posts get no matchups and no response counts. The app doesn't call `checkUsername`; signup claims `Usernames/{name}` in a transaction instead.
- `firestore.indexes.json` now has the composite indexes `createMatchup`, the voting queue and `onCommentPageWritten` need, but none are deployed; the emulator doesn't enforce indexes. Production's indexes are the older set. The `random` index on Posts is unused by the app.
- Requests sent by email get no notification: the server sees only the email's hash. Storing `EmailHashes/{hash} -> uid` at signup would fix it.
- Seeded matchups belong to the prompt day the seed ran on, which rolls over at 05:00 UTC; after that Home shows nothing to vote on. On running emulators, `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npm --prefix functions run seed:answers` answers today's prompts as the test accounts (accounts, prompts, friends and streaks stay as they are); then `finish-day` gives the day before its results. Once the seeded prompt days run out, re-run the full seed.
- The repo's functions are on Node 20, but the deployed `checkUsername` is still Node 18.
- All iOS plugins are Swift packages now, but `ios/` still has CocoaPods integration (`Podfile`, `Pods/`, includes in `Flutter/Debug.xcconfig` and `Release.xcconfig`). Flutter warns about it on every build; it is harmless but slows builds.
- The old username lists on `Users` (`friendsList`, `pendingFriendsList`) and the legacy `friend()` in `lib/data/friends.dart` still back the Past feed's profile popup; move it to the new friends and drop them.
- Emails aren't verified at signup, so someone could register with another person's email and receive friend requests sent to it. Require verification before reading `EmailRequests`.
- More suspected bugs are recorded as `TODO(bug)` in `test/data/` and `test/state/`.
- The repo's Firestore rules are explicit for slice 1 but still let any signed-in user edit other users' `Users` docs and posts (legacy friend requests and voting need it); tighten them in the friends and voting slices. Production still runs the old open rules: nothing has been deployed.
- Storage rules deny everything.
- The bundle ID is still `com.example.chuckler`. It needs a permanent ID registered in Firebase.
- `fb_em_data/` now holds only `@chuckler.test` accounts, but older commits still contain an export with real emails.
- Simulator.app is missing from this Xcode 27 install, so test on a real iPhone.
