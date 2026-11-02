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
# Physical iPhone: point it at the Mac's LAN IP
flutter run --dart-define=USE_EMULATOR=true --dart-define=EMULATOR_HOST=192.168.1.x
# Without the flag the app talks to PRODUCTION Firebase
flutter run
```

Firebase emulators (auth 9099, firestore 8080, functions 5001, storage 9199, UI enabled). Seed data is in `fb_em_data/`:

```bash
firebase emulators:start --import=fb_em_data [--export-on-exit=fb_em_data]
```

Cloud Functions (`functions/`, Node 18, ESLint google config; lint runs as a predeploy step):

```bash
cd functions && npm install && npm run lint
npm run deploy        # firebase deploy --only functions
```

Emulator mode is opt-in only, through `USE_EMULATOR`. Never hardcode emulator calls into `lib/main.dart`. Builds without the flag must hit production.

Tests run without Firebase: `test/data/` covers the query functions against `fake_cloud_firestore` (shared fixtures in `test/data/helpers.dart`), and `test/state/` covers the ChangeNotifier services. They are characterization tests: they describe current behavior, and suspected bugs are matched as-is and marked `TODO(bug)` rather than fixed. `test/widgets/` renders individual screens with fake services at iPhone sizes; `MyApp` itself is not tested, because it needs Firebase and Isar to start.

## Architecture

**Startup (`lib/main.dart`)**: opens the Isar DB, initializes Firebase (`lib/firebase/firebase_options.dart`), optionally connects the emulators, then wraps `MyApp` in a `MultiProvider` that supplies:
- Three `ChangeNotifier`s in `lib/state/`:
  - `SessionService`: the logged-in `DbUser`, last login time and `firstLogin`.
  - `PromptService`: today's prompts and the user's post for each one; `logout()` clears these (and only these).
  - `FeedService`: feed posts, the current feed prompt id, and the viewing post/color.
  Screens look up only the services they read, e.g. `Provider.of<SessionService>(context, listen: false)`.
- `IsarService` (`lib/database/isarDB.dart`), the local on-device cache.
- `FirebaseFirestore.instance`, injected so query functions receive it as a parameter.

**Navigation**: `lib/route_generator.dart` has the named routes `/` (login), `/signup`, `/app`. `/app` opens `NavigationBarController` (`lib/AppNavBar.dart`), a bottom-nav shell that swaps between pages in `lib/pages/` (create, feed, leaderboard, account, ...) by index rather than with routes.

**Data layer: two tiers**
- Remote: `lib/data/` holds top-level async Firestore functions grouped by feature: `prompts.dart`, `posts.dart`, `users.dart`, `friends.dart`, `comments.dart`. Each takes a `FirebaseFirestore` argument. Firestore collections: `Users`, `Posts`, `Comments`, `PromptDays`, `MatchUps`, `Notifications`.
- When today has no prompt, `getDailyPrompts` returns a placeholder prompt (`awaitingPrompt()`, checked with `isAwaitingPrompt`). It has a null date so the Isar cache never serves it, and the create page refuses to post to it.
- Local: Isar (the community fork, `isar_community` 3.4.x, which supports Swift Package Manager) models in `lib/database/models.dart` (`DbPost`, `DbPrompt`, `DbUser`, `DbComment`, `DbNotification`). `models.g.dart` is generated, so don't hand-edit it. Fetched Firestore data is mapped into these models, cached in Isar, and pushed into the `lib/state/` services for the UI.
- `lib/db.dart` is an older SharedPreferences-based store, still used by the login flow for things like caching the last login time.

**Server-side logic (`functions/index.js`)**: Firestore triggers on `Posts/{docid}` creation:
- `createMatchup` pairs the new post with the oldest unmatched post for the same `promptId` + `promptDateId` and writes a `MatchUps` doc, or marks the post `matched: false`.
- `incrementPrompt` bumps the response count on the matching `PromptDays` prompt.
Matchups exist only because of these triggers. The app itself does not read `MatchUps` yet: the feed is built from `Posts` via `getPosts`.

**Rules/config**: `firestore.rules`, `storage.rules`, `firestore.indexes.json`, all wired up in `firebase.json`.

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

Planned features (Create-tab prompt swiping, swipe-based Home voting) are in `TODO.md`.

- Signup calls `httpsCallable('checkUsername')`, which is not defined in `functions/index.js`.
- Cloud Functions run on Node 18, which Google has retired. Move to Node 20+ before any deploy.
- All iOS plugins are Swift packages now, but `ios/` still has CocoaPods integration (`Podfile`, `Pods/`, includes in `Flutter/Debug.xcconfig` and `Release.xcconfig`). Flutter warns about it on every build; it is harmless but slows builds.
- Logout (`lib/pages/accountpage/settings.dart`) navigates to `'/login'`, which is not a defined route, so the default route builds a second `MyApp` inside the first.
- Logout clears only prompts and the user's posts; `SessionService` and `FeedService` keep the previous user's state.
- More suspected bugs are recorded as `TODO(bug)` in `test/data/` and `test/state/`.
- Firestore rules are intentionally open to any signed-in user while the live database holds only test accounts. Tighten them before real users arrive or before moving to the Blaze plan.
- Storage rules deny everything.
- The bundle ID is still `com.example.chuckler`. It needs a permanent ID registered in Firebase.
- `fb_em_data/` is committed and contains emulator accounts with real emails.
- Simulator.app is missing from this Xcode 27 install, so test on a real iPhone.
