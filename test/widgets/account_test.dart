// Regression tests for the Account tab: a username with stray spaces used to
// crash ProfilePicture with a RangeError, and the fixed-height header
// overflowed on every iPhone size.

import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/accountpage/account.dart';
import 'package:chuckler/state/session_service.dart';
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
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: session,
          child: const MaterialApp(home: Account()),
        ));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text(username), findsWidgets);
      });
    }
  }
}
