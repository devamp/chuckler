// The streak calendar sheet closes by pulling down or with its button, not
// only by tapping above it.

import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/createpage/create_streak_sheet.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/state/moderation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    Future<void> open(WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final session = SessionService()
        ..setLoggedInUser(DbUser('u1', 'ava', 0, 0, ''));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ModerationService()),
          ChangeNotifierProvider.value(value: session),
          ChangeNotifierProvider.value(value: FriendsService()),
          Provider<FirebaseFirestore>.value(value: FakeFirebaseFirestore()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                  onPressed: () => showStreakSheet(context, 3, sample: true),
                  child: const Text('open')),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('3 DAY STREAK'), findsOneWidget);
    }

    testWidgets('pulling down on the calendar closes it ($platform)',
        (tester) async {
      await open(tester);
      await tester.drag(find.text('3 DAY STREAK'), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(find.text('3 DAY STREAK'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('the Close button closes it ($platform)', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('3 DAY STREAK'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('a small pull leaves it open', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = SessionService()
      ..setLoggedInUser(DbUser('u1', 'ava', 0, 0, ''));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModerationService()),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: FriendsService()),
        Provider<FirebaseFirestore>.value(value: FakeFirebaseFirestore()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
                onPressed: () => showStreakSheet(context, 3, sample: true),
                child: const Text('open')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.timedDrag(find.text('3 DAY STREAK'), const Offset(0, 30),
        const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('3 DAY STREAK'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
