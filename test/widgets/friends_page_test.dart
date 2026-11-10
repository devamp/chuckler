// Widget tests for the Friends screen, against a fake Firestore.

import 'package:chuckler/data/friends.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/friends/friends_page.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/state/moderation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'fonts.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FriendsService friends;

  Future<void> settle(WidgetTester tester) async {
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Future<void> pumpFriends(WidgetTester tester,
      {Size size = const Size(393, 852)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    firestore = FakeFirebaseFirestore();
    friends = FriendsService();
    await tester.runAsync(() async {
      for (final (uid, name) in [
        ('u-ava', 'ava'),
        ('u-ben', 'ben'),
        ('u-cleo', 'cleo'),
        ('u-dev', 'dev'),
      ]) {
        await firestore.doc('Users/$uid').set({'username': name});
        await firestore.doc('Usernames/$name').set({'uid': uid});
      }
      await firestore.doc('Users/u-ava/Friends/u-ben').set({'username': 'ben'});
      await firestore.doc('Users/u-ben/Friends/u-ava').set({'username': 'ava'});
      await firestore
          .doc('Users/u-ava/FriendRequests/u-dev')
          .set({'username': 'dev', 'photoUrl': ''});
      await firestore
          .doc('EmailRequests/${emailHash('ava@chuckler.test')}/From/u-cleo')
          .set({'username': 'cleo', 'photoUrl': ''});
    });
    final session = SessionService()
      ..setLoggedInUser(DbUser('u-ava', 'ava', 0, 0, ''))
      ..email = 'ava@chuckler.test';
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModerationService()),
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: friends),
        Provider<FirebaseFirestore>.value(value: firestore),
      ],
      child: const MaterialApp(home: FriendsPage()),
    ));
    await settle(tester);
  }


  testWidgets('shows requests of both kinds and the friends list',
      (tester) async {
    await pumpFriends(tester);
    expect(find.text('Requests (2)'), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
    expect(find.text('cleo'), findsOneWidget);
    expect(find.text('Your friends (1)'), findsOneWidget);
    expect(find.text('ben'), findsOneWidget);
  });

  testWidgets('sending to a username confirms and writes the request',
      (tester) async {
    await pumpFriends(tester);
    await tester.enterText(find.byType(TextField), 'cleo');
    await tester.tap(find.text('Send'));
    await settle(tester);

    expect(find.text('Request sent to cleo.'), findsOneWidget);
    final r = await tester.runAsync(
        () => firestore.doc('Users/u-cleo/FriendRequests/u-ava').get());
    expect(r!.exists, isTrue);
  });

  testWidgets('sending to an email reveals nothing', (tester) async {
    await pumpFriends(tester);
    await tester.enterText(find.byType(TextField), 'nobody@example.com');
    await tester.tap(find.text('Send'));
    await settle(tester);

    expect(
        find.text("Request sent. If someone has that email, they'll see it."),
        findsOneWidget);
  });

  testWidgets('unknown usernames and existing friends get a message',
      (tester) async {
    await pumpFriends(tester);
    await tester.enterText(find.byType(TextField), 'zed');
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(find.text('No one has that username.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ben');
    await tester.tap(find.text('Send'));
    await settle(tester);
    expect(find.text("You're already friends."), findsOneWidget);
  });

  testWidgets('accept and decline update both sections', (tester) async {
    await pumpFriends(tester);
    await tester.tap(find.text('Accept').first); // dev, by username
    await settle(tester);
    expect(find.text('Your friends (2)'), findsOneWidget);
    expect(find.text('Requests (1)'), findsOneWidget);

    await tester.tap(find.text('Decline'));
    await settle(tester);
    expect(find.textContaining('Requests'), findsNothing);
    final devSide = await tester
        .runAsync(() => firestore.doc('Users/u-dev/Friends/u-ava').get());
    expect(devSide!.exists, isTrue);
  });

  testWidgets('removing a friend asks first', (tester) async {
    await pumpFriends(tester);
    await tester.tap(find.byTooltip('More for ben'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove friend'));
    await tester.pumpAndSettle();
    expect(find.text('Remove ben?'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await settle(tester);

    expect(find.text('Your friends (0)'), findsOneWidget);
    final benSide = await tester
        .runAsync(() => firestore.doc('Users/u-ben/Friends/u-ava').get());
    expect(benSide!.exists, isFalse);
  });

  for (final size in const [Size(393, 852), Size(375, 667)]) {
    testWidgets('fits without overflow at $size', (tester) async {
      await loadRealFonts();
      await pumpFriends(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
