// Widget tests for swipe voting on the Home tab, with the sample matchups
// stored in a fake Firestore.

import 'package:chuckler/data/matchups.dart';
import 'package:chuckler/data/prompt_day.dart';
import 'package:chuckler/data/sample_matchups.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/feedpage/feed_page.dart';
import 'package:chuckler/pages/feedpage/feedpage_vote.dart';
import 'package:chuckler/pages/feedpage/feedpage_comments.dart';
import 'package:chuckler/state/prompt_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/state/voting_service.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:chuckler/pages/feedpage/matchup_filter.dart';
import 'package:chuckler/pages/friends/public_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/helpers.dart';
import 'fonts.dart';

void main() {
  late VotingService voting;
  late FakeFirebaseFirestore firestore;

  Future<void> pumpVotePage(WidgetTester tester,
      {bool tutorialSeen = true,
      Size size = const Size(393, 852),
      bool posts = true}) async {
    SharedPreferences.setMockInitialValues(
        {voteTutorialSeenKey: tutorialSeen});
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    voting = VotingService();
    firestore = FakeFirebaseFirestore();
    await tester.runAsync(() async {
      await seedMatchups(firestore, sampleMatchups(), posts: posts);
      await firestore.doc('MatchUps/sample-1/Authors/names').set({
        'answers': [
          {'username': 'skyler', 'photoUrl': ''},
          {'username': 'marco', 'photoUrl': ''},
        ],
      });
    });
    final session = SessionService()
      ..setLoggedInUser(DbUser('me', 'caden', 0, 0, ''));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: voting),
        ChangeNotifierProvider.value(value: PromptService()),
        ChangeNotifierProvider.value(value: FriendsService()),
        Provider<FirebaseFirestore>.value(value: firestore),
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

  testWidgets('after voting, each card opens its own answer\'s comments',
      (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    // the preview belongs to the answer you picked
    await tester.tap(find.text('Comments'));
    await tester.pumpAndSettle();
    expect(find.text('"Anyone know which button is autopilot?"'),
        findsOneWidget);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();

    // tapping the other card shows the other answer's thread
    await tester.tap(
        answer('Okay, this is my first time without the simulator'));
    await tester.pumpAndSettle();
    expect(find.text('"Okay, this is my first time without the simulator"'),
        findsOneWidget);
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

  testWidgets('a refused vote is taken back with a message',
      (tester) async {
    // with no Posts docs the downvote's batch fails
    await pumpVotePage(tester, posts: false);

    await tester.drag(
        answer('Okay, this is my first time without the simulator'),
        const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text("Your vote didn't go through"), findsOneWidget);
    expect(voting.hasVoted(voting.current!), isFalse);
    expect(find.byTooltip('Downvote this answer'), findsNWidgets(2));
  });

  testWidgets('votes are saved to Firestore', (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    final vote = await tester
        .runAsync(() => firestore.doc('Votes/sample-1_me').get());
    expect(vote!.data()!['type'], 'win');
    expect(vote.data()!['card'], 0);
  });

  testWidgets('the comment sheet loads the thread and posts a comment',
      (tester) async {
    await pumpVotePage(tester);
    await tester.runAsync(() => firestore
            .collection('Posts')
            .doc('s1a')
            .collection('CommentPages')
            .doc('0')
            .set({
          'comments': {
            'c1': {
              'uid': 'u-ben',
              'username': 'ben',
              'text': 'pilots hate this',
              'at': Timestamp.fromDate(DateTime.utc(2026, 11, 8)),
            },
          },
        }));
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Comments'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.textContaining('pilots hate this', findRichText: true),
        findsOneWidget);

    await tester.enterText(find.byType(TextField), 'same');
    await tester.pump();
    await tester.tap(find.byTooltip('Post comment'));
    await tester.pump();
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.textContaining('same', findRichText: true), findsOneWidget);
    final page = await tester.runAsync(() => firestore
        .doc('Posts/s1a/CommentPages/0')
        .get());
    expect((page!.data()!['comments'] as Map), hasLength(2));
  });

  testWidgets('the caught-up screen can check for new matchups',
      (tester) async {
    await pumpVotePage(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Check for new matchups'), findsOneWidget);

    await tester.tap(find.text('Check for new matchups'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    // skipped matchups come back, since there's no vote on them
    expect(voting.index, 0);
    expect(voting.length, 5);
  });

  testWidgets('authors stay hidden until you vote, then both show',
      (tester) async {
    await pumpVotePage(tester);
    expect(find.text('skyler'), findsNothing);
    expect(find.text('marco'), findsNothing);

    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('skyler'), findsOneWidget);
    expect(find.text('marco'), findsOneWidget);
  });

  testWidgets('a downvote reveals the authors too', (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Okay, this is my first time without the simulator'),
        const Offset(-300, 0));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('skyler'), findsOneWidget);
    expect(find.text('marco'), findsOneWidget);
  });

  testWidgets('authors stay when you come back to a voted matchup',
      (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('skyler'), findsNothing);

    await tester.tap(find.byTooltip('Previous matchup'));
    await tester.pumpAndSettle();
    expect(find.text('skyler'), findsOneWidget);
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

  testWidgets('swiping up moves on, swiping down returns to a final vote',
      (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.pumpAndSettle();

    await tester.fling(find.textContaining('your pilot say', findRichText: true),
        const Offset(0, -300), 1000);
    await tester.pumpAndSettle();
    expect(answer('Hold my coffee'), findsOneWidget);

    await tester.fling(answer('Hold my coffee'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(answer('Anyone know which button is autopilot?'), findsOneWidget);
    expect(find.text('Your pick'), findsOneWidget);
  });

  testWidgets('the back button also returns to the previous matchup',
      (tester) async {
    await pumpVotePage(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Previous matchup'));
    await tester.pumpAndSettle();

    expect(voting.index, 0);
  });

  testWidgets('slow drags work in both directions', (tester) async {
    await pumpVotePage(tester);

    await tester.timedDrag(answer('Anyone know which button is autopilot?'),
        const Offset(0, -200), const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(voting.index, 1);

    await tester.timedDrag(answer('Hold my coffee'), const Offset(0, 200),
        const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(voting.index, 0);
  });

  testWidgets('swiping down on the first matchup stays put', (tester) async {
    await pumpVotePage(tester);

    await tester.fling(answer('Anyone know which button is autopilot?'),
        const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(voting.index, 0);
  });

  testWidgets('a short vertical drag does nothing', (tester) async {
    await pumpVotePage(tester);

    await tester.timedDrag(answer('Anyone know which button is autopilot?'),
        const Offset(0, -40), const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(voting.index, 0);
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

    // swiping down from the end returns to the last matchup
    await tester.fling(find.textContaining("You're all caught up"),
        const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(voting.index, 4);
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

  for (final size in const [Size(393, 852), Size(375, 667)]) {
    testWidgets('Home opens on voting with the filter, no Past, at $size',
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
          ChangeNotifierProvider.value(value: PromptService()),
          Provider<FirebaseFirestore>.value(value: FakeFirebaseFirestore()),
        ],
        child: const MaterialApp(home: Scaffold(body: FeedPage())),
      ));
      await tester.pumpAndSettle();

      // the Past view is hidden for the first release
      expect(find.text('Past'), findsNothing);
      expect(find.text('All'), findsOneWidget);
      expect(find.byType(VotePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders without overflow on an iPhone SE after voting',
      (tester) async {
    await loadRealFonts();
    await pumpVotePage(tester, size: const Size(375, 667));
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('skyler'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the filter menu filters matchups', (tester) async {
    await loadRealFonts();
    SharedPreferences.setMockInitialValues({voteTutorialSeenKey: true});
    voting = VotingService();
    firestore = FakeFirebaseFirestore();
    await tester.runAsync(() => seedMatchups(firestore, sampleMatchups()));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
            value: SessionService()
              ..setLoggedInUser(DbUser('me', 'caden', 0, 0, ''))),
        ChangeNotifierProvider.value(value: voting),
        ChangeNotifierProvider.value(value: PromptService()),
        Provider<FirebaseFirestore>.value(value: firestore),
      ],
      child: const MaterialApp(home: Scaffold(body: FeedPage())),
    ));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(answer('Anyone know which button is autopilot?'), findsOneWidget);

    await tester.tap(find.byType(MatchupFilterButton));
    await tester.pumpAndSettle();
    Finder menuItem(String label) => find.descendant(
        of: find.byType(PopupMenuItem<MatchupFilter>),
        matching: find.text(label));
    expect(menuItem('All'), findsOneWidget);
    expect(menuItem('Global'), findsOneWidget);
    expect(find.text('Prompts your friends wrote'), findsOneWidget);
    await tester.tap(menuItem('Friends'));
    await tester.pumpAndSettle();
    expect(voting.filter, MatchupFilter.friends);
    expect(find.textContaining('No friend prompts to vote on yet'),
        findsOneWidget);
    expect(answer('Anyone know which button is autopilot?'), findsNothing);

    await tester.tap(find.byType(MatchupFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(menuItem('Global'));
    await tester.pumpAndSettle();
    expect(answer('Anyone know which button is autopilot?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the comment sheet is half height and closes with its button',
      (tester) async {
    await pumpVotePage(tester);
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comments'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final sheet = tester.getSize(find.byType(AnswerCommentsSheet));
    expect(sheet.height, lessThanOrEqualTo(852 * 0.5 + 1));
    expect(find.textContaining('Start the conversation'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AnswerCommentsSheet), findsNothing);
  });

  testWidgets("tapping an author opens their profile to add them",
      (tester) async {
    await pumpVotePage(tester);
    await tester.runAsync(() async {
      await firestore.doc('Usernames/skyler').set({'uid': 'u-sky'});
      await firestore.doc('Users/u-sky').set({'username': 'skyler'});
    });
    await tester.drag(
        answer('Anyone know which button is autopilot?'), const Offset(300, 0));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('skyler'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.byType(PublicProfilePage), findsOneWidget);
    expect(find.textContaining('Become friends to see'), findsOneWidget);

    await tester.tap(find.text('Add friend'));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Requested'), findsOneWidget);
    final request = await tester.runAsync(
        () => firestore.doc('Users/u-sky/FriendRequests/me').get());
    expect(request!.exists, isTrue);
    expect(request.data()!['username'], 'caden');
    expect(tester.takeException(), isNull);
  });

  testWidgets("Friends shows matchups for friend prompts you're in",
      (tester) async {
    await loadRealFonts();
    SharedPreferences.setMockInitialValues({voteTutorialSeenKey: true});
    voting = VotingService();
    firestore = FakeFirebaseFirestore();
    final now = DateTime.now().toUtc();
    await tester.runAsync(() async {
      await seedMatchups(firestore, sampleMatchups());
      await firestore.collection('MatchUps').doc('friends-1').set({
        ...matchupDoc(sampleMatchups().first,
            dayId: promptDayId(now), createdAt: now),
        'before': 'Ben wants to know: ',
        'after': '?',
        'scope': 'friends',
        'audience': ['me', 'ben', 'cleo'],
        'postIds': ['fb', 'fc'],
        'answers': [
          {'postId': 'fb', 'answer': 'a haunted toaster'},
          {'postId': 'fc', 'answer': 'three raccoons'},
        ],
      });
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
            value: SessionService()
              ..setLoggedInUser(DbUser('me', 'caden', 0, 0, ''))),
        ChangeNotifierProvider.value(value: voting),
        ChangeNotifierProvider.value(value: PromptService()),
        Provider<FirebaseFirestore>.value(value: firestore),
      ],
      child: const MaterialApp(home: Scaffold(body: FeedPage())),
    ));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(voting.countFor(MatchupFilter.friends), 1);
    expect(voting.countFor(MatchupFilter.all), 6);

    await tester.tap(find.byType(MatchupFilterButton));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(PopupMenuItem<MatchupFilter>),
        matching: find.text('Friends')));
    await tester.pumpAndSettle();
    expect(answer('a haunted toaster'), findsOneWidget);
    expect(answer('three raccoons'), findsOneWidget);
    expect(find.textContaining('Ben wants to know', findRichText: true),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('answers carry no friends or global label', (tester) async {
    await pumpVotePage(tester);
    // sample-2 is a friends matchup; its answers look like any others
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Friends'), findsNothing);
    expect(find.text('Global'), findsNothing);
    expect(find.byIcon(Icons.people), findsNothing);
    expect(find.byIcon(Icons.public), findsNothing);
  });

  testWidgets('the page follows the finger and the next one slides in',
      (tester) async {
    await pumpVotePage(tester);
    final first = answer('Anyone know which button is autopilot?');
    final startY = tester.getCenter(first).dy;

    final gesture = await tester.startGesture(tester.getCenter(first));
    await gesture.moveBy(const Offset(0, -30));
    await gesture.moveBy(const Offset(0, -170));
    await tester.pump();
    // mid-swipe: both matchups on screen, nothing moved in the queue yet
    expect(tester.getCenter(first).dy, lessThan(startY - 150));
    expect(answer('Hold my coffee'), findsOneWidget);
    expect(voting.index, 0);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100));
    // still sliding
    expect(voting.index, 0);
    await tester.pumpAndSettle();
    expect(voting.index, 1);
    expect(first, findsNothing);
    expect(answer('Hold my coffee'), findsOneWidget);
  });

  testWidgets('a short drag springs back without moving', (tester) async {
    await pumpVotePage(tester);
    final first = answer('Anyone know which button is autopilot?');
    final startY = tester.getCenter(first).dy;
    await tester.timedDrag(first, const Offset(0, -60),
        const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    expect(voting.index, 0);
    expect(tester.getCenter(first).dy, moreOrLessEquals(startY));
  });

  group('pull down to refresh', () {
    Future<void> addMatchup(WidgetTester tester) async {
      await tester.runAsync(() async {
        final first = await firestore.doc('MatchUps/sample-1').get();
        await firestore.doc('MatchUps/fresh-1').set({
          ...first.data()!,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    }

    testWidgets('on the first matchup it reloads', (tester) async {
      await pumpVotePage(tester);
      final before = voting.length;
      await addMatchup(tester);

      final first = answer('Anyone know which button is autopilot?');
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(const Offset(0, 30));
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      expect(find.text('Release to refresh'), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.runAsync(
          () => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(voting.length, before + 1);
      expect(voting.index, 0);
      expect(find.text('Release to refresh'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a short pull shows the hint but does not reload',
        (tester) async {
      await pumpVotePage(tester);
      final before = voting.length;
      await addMatchup(tester);
      final first = answer('Anyone know which button is autopilot?');
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(const Offset(0, 30));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(find.text('Pull to refresh'), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(voting.length, before);
    });

    testWidgets('with a matchup behind, pulling down goes back instead',
        (tester) async {
      await pumpVotePage(tester);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      final gesture = await tester
          .startGesture(tester.getCenter(answer('Hold my coffee')));
      await gesture.moveBy(const Offset(0, 30));
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();
      expect(find.text('Release to refresh'), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(voting.index, 0);
    });
  });
}
