// Settings: account details, change password, hidden prompts, logging out
// and deleting the account, with a fake Firestore and a mock FirebaseAuth.

import 'dart:io';

import 'package:chuckler/data/matchups.dart';
import 'package:chuckler/data/moderation.dart';
import 'package:chuckler/pages/accountpage/settings-routes/blocked_users_page.dart';
import 'package:chuckler/pages/accountpage/settings-routes/content_filter_page.dart';
import 'package:chuckler/data/prompt_day.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/accountpage/settings.dart';
import 'package:chuckler/pages/accountpage/settings-routes/delete_account_page.dart';
import 'package:chuckler/pages/accountpage/settings-routes/hidden_prompts_page.dart';
import 'package:chuckler/state/account_service.dart';
import 'package:chuckler/state/create_service.dart';
import 'package:chuckler/state/feed_service.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:chuckler/state/leaderboard_service.dart';
import 'package:chuckler/state/prompt_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/state/voting_service.dart';
import 'package:chuckler/state/moderation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:provider/provider.dart';

import 'fonts.dart';

void main() {
  late SessionService session;
  late VotingService voting;
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore firestore;
  late ModerationService moderation;

  setUp(() {
    session = SessionService()
      ..setLoggedInUser(DbUser('u1', 'ava', 0, 0, ''))
      ..email = 'ava@chuckler.test';
    voting = VotingService();
    auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'ava@chuckler.test'));
    firestore = FakeFirebaseFirestore();
    moderation = ModerationService(
        loadCategories: () async => parseWordList(
            File('functions/wordlist.json').readAsStringSync()));
  });

  Future<void> pump(WidgetTester tester, Widget home,
      {Size size = const Size(393, 852),
      Future<void> Function(FakeFirebaseFirestore f)? seed}) async {
    await loadRealFonts();
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (seed != null) await seed(firestore);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: moderation),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: voting),
        ChangeNotifierProvider.value(value: PromptService()),
        ChangeNotifierProvider.value(value: CreateService()),
        ChangeNotifierProvider.value(value: FriendsService()),
        ChangeNotifierProvider.value(
            value: AccountService(loadCatalog: () async => [])),
        ChangeNotifierProvider.value(value: LeaderboardService()),
        ChangeNotifierProvider.value(value: FeedService()),
        Provider<FirebaseFirestore>.value(value: firestore),
      ],
      // like the app: routes by name, '/' being the login screen
      child: MaterialApp(
        initialRoute: '/test',
        onGenerateRoute: (s) => MaterialPageRoute(
            settings: s,
            builder: (_) => s.name == '/test'
                ? home
                : Scaffold(body: Text('route ${s.name}'))),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Widget settings() =>
      Settings(auth: auth, versionLoader: () async => '1.0.0 (1)');

  for (final size in const [Size(393, 852), Size(375, 667)]) {
    testWidgets('shows your account and no placeholder sections at $size',
        (tester) async {
      await pump(tester, settings(), size: size);
      expect(find.text('ava'), findsWidgets);
      expect(find.text('ava@chuckler.test'), findsWidgets);
      expect(find.text('1.0.0 (1)'), findsOneWidget);
      expect(find.text('Hidden prompts'), findsOneWidget);
      for (final gone in ['Subscription', 'Security', 'Release Notes']) {
        expect(find.text(gone), findsNothing);
      }
      await tester.scrollUntilVisible(find.text('Delete account'), 100);
      expect(find.text('Log out'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('change password emails a reset link', (tester) async {
    await pump(tester, settings());
    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();
    expect(find.textContaining('email a link to ava@chuckler.test'),
        findsOneWidget);
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();
    expect(find.text('Check ava@chuckler.test for the reset link'),
        findsOneWidget);
  });

  testWidgets('log out returns to login and clears the user', (tester) async {
    await pump(tester, settings());
    await tester.scrollUntilVisible(find.text('Log out'), 100);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out of Chuckler?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('route /'), findsOneWidget);
    // nothing to go back to
    expect(find.byType(Settings), findsNothing);
    expect(session.loggedInUser, isNull);
    expect(session.email, isNull);
    expect(auth.currentUser, isNull);
  });

  group('hidden prompts', () {
    testWidgets("lists today's hidden prompts and unhides one",
        (tester) async {
      final today = promptDayId(DateTime.now().toUtc());
      await pump(tester, const HiddenPromptsPage(), seed: (f) async {
        await f.doc('PromptDays/$today/Prompts/p1')
            .set({'before': 'The worst pizza topping: ', 'after': '.'});
        await f.doc('FriendPrompts/u2_$today')
            .set({'before': 'Ben would never ', 'after': '.'});
        await saveHiddenPrompts(f, 'u1', today, {'p1', 'u2_$today'});
      });
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.textContaining('worst pizza topping', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('Ben would never', findRichText: true),
          findsOneWidget);

      await tester.tap(find.text('Unhide').first);
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('Unhide'), findsOneWidget);
      final left = await tester
          .runAsync(() => getHiddenPrompts(firestore, 'u1', today));
      expect(left, hasLength(1));
    });

    testWidgets('says so when nothing is hidden', (tester) async {
      await pump(tester, const HiddenPromptsPage());
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.textContaining("haven't hidden any prompts"),
          findsOneWidget);
    });
  });

  group('delete account', () {
    testWidgets('needs a password and shows a wrong one', (tester) async {
      // its own uid: MockUser compares by uid, and the thrown error below
      // stays registered for that user
      auth = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'wrong-pw', email: 'ava@chuckler.test'));
      await pump(tester, DeleteAccountPage(auth: auth));
      final button = find.widgetWithText(FilledButton, 'Delete my account');
      expect(tester.widget<FilledButton>(button).onPressed, isNull);

      whenCalling(Invocation.method(#reauthenticateWithCredential, null))
          .on(auth.currentUser!)
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));
      await tester.enterText(find.byType(TextField), 'nope');
      await tester.pump();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text("That password isn't right."), findsOneWidget);
      expect(session.loggedInUser, isNotNull);
    });

    testWidgets('deletes the account and returns to login', (tester) async {
      await pump(tester, DeleteAccountPage(auth: auth));
      await tester.enterText(find.byType(TextField), 'right-password');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete my account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('route /'), findsOneWidget);
      expect(session.loggedInUser, isNull);
    });
  });

  group('safety', () {
    testWidgets('Blocked users lists them and unblocks', (tester) async {
      await pump(tester, const BlockedUsersPage(), seed: (f) async {
        await f.doc('Users/u1/Blocked/u9')
            .set({'uid': 'u9', 'username': 'troll', 'photoUrl': ''});
      });
      await tester.runAsync(() => moderation.load(firestore, 'u1'));
      await tester.pumpAndSettle();
      expect(find.text('troll'), findsOneWidget);
      await tester.tap(find.text('Unblock'));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('troll'), findsNothing);
      expect(find.textContaining("haven't blocked anyone"), findsOneWidget);
      final doc = await tester
          .runAsync(() => firestore.doc('Users/u1/Blocked/u9').get());
      expect(doc!.exists, isFalse);
    });

    testWidgets('Content filter shows the defaults and saves a change',
        (tester) async {
      await pump(tester, const ContentFilterPage());
      await tester.runAsync(() => moderation.load(firestore, 'u1'));
      await tester.pumpAndSettle();
      bool on(String label) => tester
          .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label))
          .value;
      expect(on('Hate speech & slurs'), isTrue);
      expect(on('Sexual content'), isTrue);
      expect(on('Strong language'), isFalse);

      await tester.tap(find.text('Strong language'));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(on('Strong language'), isTrue);
      final saved =
          await tester.runAsync(() => getContentFilter(firestore, 'u1'));
      expect(saved, {'slurs', 'sexual', 'profanity'});
    });

    testWidgets('Settings has a Safety section', (tester) async {
      await pump(tester, settings());
      expect(find.text('Content filter'), findsOneWidget);
      expect(find.text('Blocked users'), findsOneWidget);
    });
  });
}
