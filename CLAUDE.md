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

Firebase emulators (auth 9099, firestore 8080, functions 5001, storage 9199, UI enabled). Seed data is in `fb_em_data/`: the Chuckler account, test accounts `ava`/`ben`/`cleo` `@chuckler.test` (password in `functions/scripts/seed.js`), and prompt days around the day it was made:

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

Emulator mode is opt-in only, through `USE_EMULATOR`. Never hardcode emulator calls into `lib/main.dart`. Builds without the flag must hit production.

Tests run without Firebase: `test/data/` covers the query functions against `fake_cloud_firestore` (shared fixtures in `test/data/helpers.dart`), and `test/state/` covers the ChangeNotifier services. They are characterization tests: they describe current behavior, and suspected bugs are matched as-is and marked `TODO(bug)` rather than fixed. `test/widgets/` renders individual screens with fake services at iPhone sizes (`test/widgets/fonts.dart` loads the real fonts for overflow checks); `MyApp` itself is not tested, because it needs Firebase and Isar to start.

## Architecture

**Startup (`lib/main.dart`)**: opens the Isar DB, initializes Firebase (`lib/firebase/firebase_options.dart`), optionally connects the emulators, then wraps `MyApp` in a `MultiProvider` that supplies:
- `ChangeNotifier`s in `lib/state/`:
  - `SessionService`: the logged-in `DbUser`, last login time and `firstLogin`.
  - `PromptService`: today's prompts and the user's post for each one; `logout()` clears these (and only these).
  - `FeedService`: feed posts, the current feed prompt id, and the viewing post/color.
  - `VotingService`: the Home tab's swipe-voting queue, the user's votes and the back history.
  - `CreateService`: the Create tab's prompt pages (live prompts, plus sample prompts in debug builds when none is live), the user's answer or draft per prompt, per-prompt stats and the answer streak.
  Screens look up only the services they read, e.g. `Provider.of<SessionService>(context, listen: false)`.
- `IsarService` (`lib/database/isarDB.dart`), the local on-device cache.
- `FirebaseFirestore.instance`, injected so query functions receive it as a parameter.

**Navigation**: `lib/route_generator.dart` has the named routes `/` (login), `/signup`, `/app`. `/app` opens `NavigationBarController` (`lib/AppNavBar.dart`), a bottom-nav shell that swaps between pages in `lib/pages/` (create, feed, leaderboard, account, ...) by index rather than with routes.

**Data layer: two tiers**
- Remote: `lib/data/` holds top-level async Firestore functions grouped by feature: `prompts.dart`, `posts.dart`, `users.dart`, `friends.dart`, `comments.dart`. Each takes a `FirebaseFirestore` argument. Firestore collections: `Users`, `Posts`, `Comments`, `PromptDays`, `MatchUps`, `Notifications`.
- `lib/data/matchups.dart` (swipe voting) still runs on sample data from `sample_matchups.dart`; its `TODO(cloud)` notes list the MatchUps/Votes fields, queries, rules and Cloud Functions it needs.
- The Create tab is live on the new layout (`docs/data-model.md`, "Live in the emulator"). Prompt days roll over at 05:00 UTC (`lib/data/prompt_day.dart`); `getDailyPrompts` reads `PromptDays/{dayId}/Prompts`; `createPost` batches the post with the user's `History/{yyyy-MM}` entry; login reads today's answers from History; signup (`registerNewUser` in `lib/data/users.dart`) claims `Usernames/{name}` in a transaction. `lib/data/prompt_stats.dart` reads prompt counts, likes and the streak; sample stats are used only for the sample prompts debug builds add when no real prompt is live. Answers to sample prompts stay on the phone.
- When today has no prompt, `getDailyPrompts` returns a placeholder prompt (`awaitingPrompt()`, checked with `isAwaitingPrompt`). It has a null date so the Isar cache never serves it, and the create page refuses to post to it.
- Local: Isar (the community fork, `isar_community` 3.4.x, which supports Swift Package Manager) models in `lib/database/models.dart` (`DbPost`, `DbPrompt`, `DbUser`, `DbComment`, `DbNotification`). `models.g.dart` is generated, so don't hand-edit it. Fetched Firestore data is mapped into these models, cached in Isar, and pushed into the `lib/state/` services for the UI.
- `lib/db.dart` is an older SharedPreferences-based store, still used by the login flow for things like caching the last login time.

**Server-side logic (`functions/index.js`)**: Firestore triggers on `Posts/{docid}` creation:
- `createMatchup` pairs the new post with the oldest unmatched post for the same `promptId` + `promptDateId` and writes a `MatchUps` doc, or marks the post `matched: false`.
- `onPostCreated` bumps the prompt's `counts.answers` and, in a transaction, the author's `FriendView/profile` `stats.answers` and streak string (`functions/promptDay.js`, the JS twin of `lib/data/prompt_day.dart`).
Matchups exist only because of these triggers. The app itself does not read `MatchUps` yet: the feed is built from `Posts` via `getPosts`.

**Rules/config**: `firestore.rules`, `storage.rules`, `firestore.indexes.json`, all wired up in `firebase.json`. `firestore.rules` has explicit rules for the slice-1 collections (prompts and likes, usernames, FriendView, Private, History, new posts) and leaves the legacy collections open to signed-in users; anything else is denied.

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
- `createMatchup` queries Posts on `promptId`, `promptDateId`, `matched` and orders by `date`. No composite index covers that, so it would fail in production; the emulator doesn't enforce indexes. The `random` index on Posts is unused by the app. Deployed indexes match `firestore.indexes.json`.
- The repo's functions are on Node 20, but the deployed `checkUsername` is still Node 18.
- All iOS plugins are Swift packages now, but `ios/` still has CocoaPods integration (`Podfile`, `Pods/`, includes in `Flutter/Debug.xcconfig` and `Release.xcconfig`). Flutter warns about it on every build; it is harmless but slows builds.
- Logout (`lib/pages/accountpage/settings.dart`) navigates to `'/login'`, which is not a defined route, so the default route builds a second `MyApp` inside the first.
- Logout clears only prompts and the user's posts; `SessionService` and `FeedService` keep the previous user's state.
- More suspected bugs are recorded as `TODO(bug)` in `test/data/` and `test/state/`.
- The repo's Firestore rules are explicit for slice 1 but still let any signed-in user edit other users' `Users` docs and posts (legacy friend requests and voting need it); tighten them in the friends and voting slices. Production still runs the old open rules: nothing has been deployed.
- Storage rules deny everything.
- The bundle ID is still `com.example.chuckler`. It needs a permanent ID registered in Firebase.
- `fb_em_data/` now holds only `@chuckler.test` accounts, but older commits still contain an export with real emails.
- Simulator.app is missing from this Xcode 27 install, so test on a real iPhone.
