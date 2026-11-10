// The Leaderboard tab against a fake Firestore at iPhone sizes with real
// fonts: friends and global boards, top answers, the pinned row and empty
// states.

import 'package:chuckler/data/prompt_day.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/friends/public_profile_page.dart';
import 'package:chuckler/pages/leaderboardpage/leaderboard.dart';
import 'package:chuckler/pages/leaderboardpage/leaderboard_widgets.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:chuckler/state/leaderboard_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/state/moderation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fonts.dart';

void main() {
  late LeaderboardService service;
  final today = promptDayId(DateTime.now().toUtc());
  final yesterday = addDays(today, -1);

  Future<FakeFirebaseFirestore> seeded({bool friends = true}) async {
    final f = FakeFirebaseFirestore();
    await f.doc('Users/u1').set({'username': 'ava'});
    await f.doc('Users/u1/FriendView/profile').set({
      'stats': {'answers': 4, 'wins': 2},
      'week': {'start': weekStartId(today), 'answers': 1, 'wins': 2},
    });
    await f.doc('Users/u1/History/${historyMonthId(yesterday)}').set({
      'answers': {
        '${yesterday}_p1': {
          'promptDateId': yesterday,
          'promptId': 'p1',
          'before': 'A terrible name for a boat: ',
          'after': '.',
          'answer': 'Leaky Lucy',
          'final': {'wins': 3, 'votes': 4},
        },
      },
    });
    if (friends) {
      for (final (uid, name, wins) in [
        ('u2', 'ben', 9),
        ('u3', 'cleo', 5),
        ('u4', 'a-very-long-username-indeed', 1),
      ]) {
        await f.doc('Users/u1/Friends/$uid').set({'username': name});
        await f.doc('Users/$uid/FriendView/profile').set({
          'stats': {'answers': wins, 'wins': wins},
          'week': {'start': weekStartId(today), 'answers': 1, 'wins': wins},
        });
      }
    }
    await f.doc('Leaderboards/wins-week').set({
      'dayId': yesterday,
      'weekStart': weekStartId(yesterday),
      'entries': [
        for (final (n, v) in [('gus', 30), ('hal', 20), ('fay', 10),
          ('eli', 5)])
          {'username': n, 'photoUrl': '', 'value': v},
      ],
    });
    return f;
  }

  Future<void> pump(WidgetTester tester, FakeFirebaseFirestore firestore,
      {Size size = const Size(393, 852)}) async {
    await loadRealFonts();
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    service = LeaderboardService();
    final session = SessionService()
      ..setLoggedInUser(DbUser('u1', 'ava', 0, 0, ''));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModerationService()),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: FriendsService()),
        ChangeNotifierProvider.value(value: service),
        Provider<FirebaseFirestore>.value(value: firestore),
      ],
      child: const MaterialApp(home: Leaderboard()),
    ));
    await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(393, 852), Size(375, 667)]) {
    testWidgets('opens on friends top answers at $size', (tester) async {
      await pump(tester, await seeded(), size: size);
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.byType(TopAnswerCard), findsOneWidget);
      expect(find.text('Leaky Lucy'), findsOneWidget);
      expect(find.text('Best answers from yesterday'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('friends wins show a podium and ranked rows at $size',
        (tester) async {
      await pump(tester, await seeded(), size: size);
      await tester.tap(find.text('Wins'));
      await settle(tester);
      expect(find.byType(Podium), findsOneWidget);
      // ben 9, cleo 5, ava 2 on the podium; the long name below
      expect(find.text('ben'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('a-very-long-username-indeed'), findsOneWidget);
      expect(find.text('This week'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('global pins your row when you are off the board',
      (tester) async {
    await pump(tester, await seeded());
    await tester.tap(find.byTooltip('Choose who to rank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Global').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wins'));
    await settle(tester);
    expect(find.text('gus'), findsOneWidget);
    expect(find.text('eli'), findsOneWidget);
    expect(find.text('ava (you)'), findsOneWidget);
    expect(find.text('Not on this board yet'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // a board the server hasn't written yet
    await tester.tap(find.text('Streak'));
    await settle(tester);
    expect(find.text('Rankings appear after the first day ends.'),
        findsOneWidget);
  });

  testWidgets('tapping someone opens their profile', (tester) async {
    await pump(tester, await seeded());
    await tester.tap(find.text('Wins'));
    await settle(tester);
    await tester.tap(find.text('a-very-long-username-indeed'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicProfilePage), findsOneWidget);
  });

  testWidgets('without friends it asks you to add some', (tester) async {
    await pump(tester, await seeded(friends: false));
    // your own top answer still shows
    expect(find.text('Leaky Lucy'), findsOneWidget);
    await tester.tap(find.text('Posts'));
    await settle(tester);
    expect(find.text('Add friends to see how you stack up.'), findsOneWidget);
  });
}
