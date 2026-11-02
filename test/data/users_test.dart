// Characterization tests for lib/data/users.dart.
//
// These describe what the queries do today, not what they should do. Where
// today's behavior looks like a bug, the test still matches it and carries a
// TODO so the bug can be fixed deliberately later.

import 'package:chuckler/data/users.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  group('getLoggedInUserInfo', () {
    test('maps the user document, including friend lists', () async {
      await firestore.collection('Users').doc('u1').set(userDoc(
            friends: 2,
            friendsList: ['bob', 'carol'],
            pendingFriends: 1,
            pendingFriendsList: ['u9'],
          ));

      final user = await getLoggedInUserInfo(firestore, 'u1');

      expect(user, isNotNull);
      expect(user!.uid, 'u1');
      expect(user.username, 'alice');
      expect(user.numPosts, 3);
      expect(user.numFriends, 2);
      expect(user.friends, ['bob', 'carol']);
      expect(user.numPendingFriends, 1);
      expect(user.pendingFriends, ['u9']);
      expect(user.profilePicture, 'https://example.com/a.png');
    });

    test('pending count without a pending list gives an empty list', () async {
      await firestore.collection('Users').doc('u1').set(userDoc(pendingFriends: 2));

      final user = await getLoggedInUserInfo(firestore, 'u1');

      expect(user!.pendingFriends, isEmpty);
      expect(user.numPendingFriends, 2);
    });

    test('returns null when the user does not exist', () async {
      expect(await getLoggedInUserInfo(firestore, 'nobody'), isNull);
    });

    test('returns null when friends > 0 but friendsList is missing', () async {
      // TODO(bug): a malformed user doc makes the whole lookup return null
      // instead of a partly filled user.
      await firestore.collection('Users').doc('u1').set(userDoc(friends: 1));

      expect(await getLoggedInUserInfo(firestore, 'u1'), isNull);
    });
  });

  group('getAUser', () {
    test('maps a user with no pending friends', () async {
      await firestore.collection('Users').doc('u1').set(userDoc(friends: 1));

      final user = await getAUser(firestore, 'u1');

      expect(user, isNotNull);
      expect(user!.username, 'alice');
      expect(user.numFriends, 1);
      expect(user.numPosts, 3);
      expect(user.pendingFriends, isEmpty);
      // unlike getLoggedInUserInfo, the friends list is not loaded
      expect(user.friends, isEmpty);
    });

    test('returns null when the user has pending friends', () async {
      // TODO(bug): assigning Firestore's List<dynamic> to the List<String>
      // pendingFriends throws, and the catch returns null.
      await firestore.collection('Users').doc('u1').set(
          userDoc(pendingFriends: 1, pendingFriendsList: ['u9']));

      expect(await getAUser(firestore, 'u1'), isNull);
    });

    test('returns null when the user does not exist', () async {
      expect(await getAUser(firestore, 'nobody'), isNull);
    });
  });

  group('user updates', () {
    test('incrementNumPosts adds one to posts', () async {
      await firestore.collection('Users').doc('u1').set(userDoc(posts: 3));

      await incrementNumPosts(firestore, 'u1');

      final doc = await firestore.collection('Users').doc('u1').get();
      expect(doc.data()!['posts'], 4);
    });

    test('incrementNumPosts throws for a missing user', () async {
      expect(incrementNumPosts(firestore, 'nobody'), throwsA(anything));
    });

    test('updateProfilePhoto sets profileImage', () async {
      await firestore.collection('Users').doc('u1').set(userDoc());

      await updateProfilePhoto(firestore, 'https://example.com/b.png', 'u1');

      final doc = await firestore.collection('Users').doc('u1').get();
      expect(doc.data()!['profileImage'], 'https://example.com/b.png');
    });
  });
}
