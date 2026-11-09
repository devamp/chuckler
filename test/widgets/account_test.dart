// Regression tests for the Account tab: a username with stray spaces used to
// crash ProfilePicture with a RangeError, and the fixed-height header
// overflowed on every iPhone size.

import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/accountpage/account.dart';
import 'package:chuckler/pages/friends/friends_page.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('profilePictureName', () {
    test('leaves a clean name alone', () {
      expect(profilePictureName('caden'), 'caden');
      expect(profilePictureName('Devam Patel'), 'Devam Patel');
    });

    test('strips leading, trailing and repeated spaces', () {
      expect(profilePictureName('caden '), 'caden');
      expect(profilePictureName('  caden'), 'caden');
      expect(profilePictureName('Devam   Patel'), 'Devam Patel');
      expect(profilePictureName(' Devam \t Patel '), 'Devam Patel');
    });

    test('an all-space name becomes empty', () {
      // ProfilePicture has its own fallback for ''
      expect(profilePictureName('   '), '');
    });
  });

  const sizes = {
    'iPhone 15': Size(393, 852),
    'iPhone SE': Size(375, 667),
  };
  const usernames = ['caden', 'caden ', ' Devam  Patel '];

  for (final size in sizes.entries) {
    for (final username in usernames) {
      testWidgets('Account renders on ${size.key} for "$username"',
          (tester) async {
        tester.view.physicalSize = size.value * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final session = SessionService()
          ..setLoggedInUser(DbUser('u1', username, 0, 0, ''));
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: session),
            ChangeNotifierProvider.value(value: FriendsService()),
            Provider<FirebaseFirestore>.value(value: FakeFirebaseFirestore()),
          ],
          child: const MaterialApp(home: Account()),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(username), findsWidgets);
      });
    }
  }

  testWidgets('the Friends count shows requests and opens the Friends screen',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final firestore = FakeFirebaseFirestore();
    await tester.runAsync(() async {
      await firestore.doc('Users/u1/Friends/u2').set({'username': 'ben'});
      await firestore.doc('Users/u1/FriendRequests/u3').set({'username': 'dev'});
    });
    final session = SessionService()
      ..setLoggedInUser(DbUser('u1', 'ava', 0, 0, ''));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: FriendsService()),
        Provider<FirebaseFirestore>.value(value: firestore),
      ],
      child: const MaterialApp(home: Account()),
    ));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('Friends'), findsOneWidget);
    // 1 friend, and a badge for 1 waiting request
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
    expect((badge.label as Text).data, '1');
    expect(find.text('1'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Friends'));
    await tester.pumpAndSettle();
    expect(find.byType(FriendsPage), findsOneWidget);
  });
}
