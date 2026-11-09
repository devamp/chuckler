// The Account tab's live parts: header stats, Posts, Notifications and
// Achievements, against a fake Firestore at iPhone sizes with real fonts.

import 'dart:io';

import 'package:chuckler/data/awards.dart';
import 'package:chuckler/data/prompt_day.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/accountpage/account.dart';
import 'package:chuckler/pages/accountpage/account_posts.dart';
import 'package:chuckler/pages/accountpage/account_notifications.dart';
import 'package:chuckler/state/account_service.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fonts.dart';

Future<List<AwardTrack>> fileCatalog() async =>
    parseAwardCatalog(File('functions/awards.json').readAsStringSync());

Future<FakeFirebaseFirestore> seeded() async {
  final f = FakeFirebaseFirestore();
  final today = promptDayId(DateTime.now().toUtc());
  await f.doc('Users/u1/FriendView/profile').set({
    'stats': {'answers': 3, 'wins': 12345, 'comments': 0, 'friends': 1},
    'awards': {
      'posts': {'1': Timestamp.now()},
    },
  });
  await f.doc('Users/u1/History/${historyMonthId(today)}').set({
    'answers': {
      '${today}_p1': {
        'postId': 'post1',
        'promptDateId': today,
        'promptId': 'p1',
        'before': 'A terrible name for a boat: ',
        'after': '.',
        'answer': 'Leaky Lucy',
      },
    },
  });
  await f.doc('Posts/post1').set({
    'counts': {'wins': 4, 'votes': 7, 'comments': 1, 'dislikes': 0},
  });
  await f.doc('Users/u1/Notifications/n1').set({
    'type': 'comment',
    'text': 'ben commented on "Leaky Lucy": lol',
    'at': Timestamp.now(),
    'seen': false,
    'from': {'username': 'ben', 'photoUrl': ''},
  });
  await f.doc('Users/u1/Friends/u2').set({'username': 'ben'});
  await f.doc('Users/u1/FriendRequests/u3').set({'username': 'dev'});
  return f;
}

Future<FakeFirebaseFirestore> pumpAccount(WidgetTester tester, Size size,
    {String username = 'ava'}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  late FakeFirebaseFirestore firestore;
  await tester.runAsync(() async {
    await loadRealFonts();
    firestore = await seeded();
  });
  final session = SessionService()
    ..setLoggedInUser(DbUser('u1', username, 0, 0, ''));
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: session),
      ChangeNotifierProvider.value(value: FriendsService()),
      ChangeNotifierProvider.value(
          value: AccountService(loadCatalog: fileCatalog)),
      Provider<FirebaseFirestore>.value(value: firestore),
    ],
    child: const MaterialApp(home: Account()),
  ));
  await tester
      .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
  await tester.pumpAndSettle();
  return firestore;
}

void main() {
  const sizes = {
    'iPhone 15': Size(393, 852),
    'iPhone SE': Size(375, 667),
  };

  test('compactCount', () {
    expect(compactCount(0), '0');
    expect(compactCount(999), '999');
    expect(compactCount(1234), '1,234');
    expect(compactCount(12345), '12.3K');
    expect(compactCount(123456), '123K');
    expect(compactCount(1234567), '1.2M');
  });

  test('dayLabel', () {
    expect(dayLabel('2026-11-09', '2026-11-09'), 'Today');
    expect(dayLabel('2026-11-08', '2026-11-09'), 'Yesterday');
    expect(dayLabel('2026-10-30', '2026-11-09'), 'Oct 30');
    expect(dayLabel('2025-12-31', '2026-11-09'), 'Dec 31, 2025');
  });

  test('notificationGroup', () {
    final now = DateTime(2026, 11, 9, 12);
    expect(notificationGroup(DateTime(2026, 11, 9, 1), now), 'Today');
    expect(notificationGroup(DateTime(2026, 11, 8, 23), now), 'Yesterday');
    expect(notificationGroup(DateTime(2026, 11, 4), now), 'Last 7 days');
    expect(notificationGroup(DateTime(2026, 10, 1), now), 'Earlier');
    expect(notificationGroup(null, now), 'Earlier');
  });

  for (final size in sizes.entries) {
    testWidgets('header and Posts on ${size.key}', (tester) async {
      await pumpAccount(tester, size.value);
      expect(tester.takeException(), isNull);
      expect(find.text('3'), findsOneWidget); // posts
      expect(find.text('12.3K'), findsOneWidget); // wins
      expect(find.text('Wins'), findsOneWidget);
      expect(find.text('Likes'), findsNothing);
      expect(
          find.text('A terrible name for a boat: Leaky Lucy.',
              findRichText: true),
          findsOneWidget);
      expect(find.text('4 wins'), findsOneWidget);
      expect(find.text('7 votes'), findsOneWidget);
      expect(find.text('1 comment'), findsOneWidget);
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('Notifications on ${size.key}', (tester) async {
      final firestore = await pumpAccount(tester, size.value);
      // a dot on the tab while one is unseen
      final dot = tester.widget<Badge>(find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.byType(Badge)));
      expect(dot.isLabelVisible, isTrue);

      await tester.tap(find.text('Notifications'));
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Friend requests (1)'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('ben commented on "Leaky Lucy": lol'), findsOneWidget);

      // opening the tab marked it seen; the tab's dot goes
      final saved = await firestore.doc('Users/u1/Notifications/n1').get();
      expect(saved.data()!['seen'], isTrue);
      final after = tester.widget<Badge>(find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.byType(Badge)));
      expect(after.isLabelVisible, isFalse);
    });

    testWidgets('Achievements on ${size.key}', (tester) async {
      await pumpAccount(tester, size.value);
      await tester.tap(find.text('Achievements'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('First Post'), findsOneWidget);
      expect(find.text('3 / 100'), findsOneWidget);
      expect(find.text('Streaker'), findsOneWidget);
      expect(find.text('Coming soon'), findsNWidgets(3));
      expect(find.text('1 of 6 earned'), findsOneWidget);

      await tester.tap(find.text('First Post'));
      await tester.pumpAndSettle();
      expect(find.text('100 Posts'), findsOneWidget);
      expect(find.text('Answer 100 prompts.'), findsOneWidget);
      expect(find.textContaining('Earned '), findsOneWidget);
    });
  }
}
