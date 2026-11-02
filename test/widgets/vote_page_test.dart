// Widget tests for swipe voting on the Home tab, running on sample matchups.

import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/feedpage/feed_page.dart';
import 'package:chuckler/pages/feedpage/feedpage_vote.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/state/voting_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late VotingService voting;

  Future<void> pumpVotePage(WidgetTester tester,
      {bool tutorialSeen = true, Size size = const Size(393, 852)}) async {
    SharedPreferences.setMockInitialValues(
        {voteTutorialSeenKey: tutorialSeen});
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    voting = VotingService();
    final session = SessionService()
      ..setLoggedInUser(DbUser('me', 'caden', 0, 0, ''));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: voting),
        Provider<FirebaseFirestore>.value(value: FakeFirebaseFirestore()),
      ],
      child: const MaterialApp(home: Scaffold(body: VotePage())),
    ));
    await tester.pumpAndSettle();
  }

  Finder answer(String text) => find.text(text);

  testWidgets('shows the first matchup with its prompt and both answers',
      (tester) async {
    await pumpVotePage(tester);

    expect(find.textContaining('your pilot say', findRichText: true),
        findsOneWidget);
    expect(answer('Anyone know which button is autopilot?'), findsOneWidget);
    expect(answer('Okay, this is my first time without the simulator'),
        findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.textContaining('% picked this'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping right on a card picks it and shows the results',
      (tester) async {
    await pumpVotePage(tester);

    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    // 31 + 1 wins vs 19
    expect(find.text('63% picked this'), findsOneWidget);
    expect(find.text('37% picked this'), findsOneWidget);
    expect(find.text('Your pick'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(voting.voteFor(voting.current!)!.card, 0);
  });

  testWidgets('swiping left on a card downvotes it', (tester) async {
    await pumpVotePage(tester);

    await tester.drag(
        answer('Okay, this is my first time without the simulator'),
        const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('You downvoted'), findsOneWidget);
    // a downvote adds no wins, so percentages stay 62 / 38
    expect(find.text('62% picked this'), findsOneWidget);
    expect(find.text('38% picked this'), findsOneWidget);
  });

  testWidgets('a short drag does not vote', (tester) async {
    await pumpVotePage(tester);

    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(voting.hasVoted(voting.current!), isFalse);
    expect(find.textContaining('% picked this'), findsNothing);
  });

  testWidgets('votes are final: further swipes and buttons do nothing',
      (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    await tester.drag(
        answer('Okay, this is my first time without the simulator'),
        const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('63% picked this'), findsOneWidget);
    expect(find.byTooltip('Pick this answer as the winner'), findsNothing);
  });

  testWidgets('swiping down moves on, and back returns to a final vote',
      (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    await tester.fling(find.textContaining('your pilot say', findRichText: true),
        const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(answer('Hold my coffee'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous matchup'));
    await tester.pumpAndSettle();
    expect(answer('Anyone know which button is autopilot?'), findsOneWidget);
    expect(find.text('Your pick'), findsOneWidget);
  });

  testWidgets('buttons vote and skip like the gestures', (tester) async {
    await pumpVotePage(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(answer('Hold my coffee'), findsOneWidget);

    await tester.tap(find.byTooltip('Pick this answer as the winner').last);
    await tester.pumpAndSettle();
    expect(voting.voteFor(voting.current!)!.card, 1);

    await tester.tap(find.byTooltip('Previous matchup'));
    await tester.pumpAndSettle();
    // the skipped matchup can still be voted on
    expect(find.byTooltip('Downvote this answer'), findsNWidgets(2));
  });

  testWidgets('going through every matchup shows the caught-up message',
      (tester) async {
    await pumpVotePage(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining("You're all caught up"), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
  });

  testWidgets('the tutorial shows once and is dismissed with Got it',
      (tester) async {
    await pumpVotePage(tester, tutorialSeen: false);

    expect(find.text('How to vote'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('How to vote'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(voteTutorialSeenKey), isTrue);
  });

  // The default test font draws every glyph as a full square, which makes
  // text far wider than on a phone. Load the app's OpenSans, also under the
  // default family name, so the Home top row is measured realistically.
  Future<void> loadRealFonts() async {
    for (final family in ['OpenSans', 'Roboto', '.SF UI Text', '.SF Pro Text']) {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/OpenSans-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/OpenSans-Bold.ttf'));
      await loader.load();
    }
  }

  for (final size in const [Size(393, 852), Size(375, 667)]) {
    testWidgets('Home opens on Vote, with the toggle fitting at $size',
        (tester) async {
      await loadRealFonts();
      SharedPreferences.setMockInitialValues({voteTutorialSeenKey: true});
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final session = SessionService()
        ..setLoggedInUser(DbUser('me', 'caden', 0, 0, ''));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider.value(value: VotingService()),
          Provider<FirebaseFirestore>.value(value: FakeFirebaseFirestore()),
        ],
        child: const MaterialApp(home: Scaffold(body: FeedPage())),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Vote'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.byType(VotePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders without overflow on an iPhone SE after voting',
      (tester) async {
    await pumpVotePage(tester, size: const Size(375, 667));
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
