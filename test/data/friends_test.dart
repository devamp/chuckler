// Characterization tests for lib/data/friends.dart.
//
// These describe what the queries do today, not what they should do. Where
// today's behavior looks like a bug, the test still matches it and carries a
// TODO so the bug can be fixed deliberately later.

import 'package:chuckler/data/friends.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  group('friend', () {
    setUp(() async {
      await firestore.collection('Users').doc('u1').set(userDoc(username: 'alice'));
      await firestore.collection('Users').doc('u2').set(userDoc(username: 'bob'));
    });

    test('a request adds the requester to the target\'s pending list', () async {
      final result =
          await friend(firestore, 'u1', 'u2', 'alice', 'bob', [], false);

      expect(result, 0);
      final bob = (await firestore.collection('Users').doc('u2').get()).data()!;
      expect(bob['pendingFriendsList'], ['u1']);
      expect(bob['pendingFriends'], 1);
      final alice = (await firestore.collection('Users').doc('u1').get()).data()!;
      expect(alice['pendingFriends'], 0);
      expect(await firestore.collection('Notifications').get(),
          predicate<QuerySnapshot>((s) => s.docs.isEmpty));
    });

    test('accepting moves the request into both friends lists', () async {
      // u2 (bob) accepts a pending request from u1 (alice)
      await firestore.collection('Users').doc('u2').update({
        'pendingFriendsList': ['u1'],
        'pendingFriends': 1,
      });

      final result = await friend(
          firestore, 'u2', 'u1', 'bob', 'alice', ['carol'], true);

      // TODO(bug): always returns 0, though the doc comment promises 1 when
      // friended and -1 on error.
      expect(result, 0);
      final bob = (await firestore.collection('Users').doc('u2').get()).data()!;
      expect(bob['pendingFriendsList'], isEmpty);
      expect(bob['pendingFriends'], 0);
      expect(bob['friends'], 1);
      // TODO(bug): pending lists hold uids, but friends lists hold usernames
      expect(bob['friendsList'], ['alice']);
      final alice = (await firestore.collection('Users').doc('u1').get()).data()!;
      expect(alice['friends'], 1);
      expect(alice['friendsList'], ['bob']);

      final notes = await firestore.collection('Notifications').get();
      final note = notes.docs.single.data();
      expect(note['type'], 0);
      expect(note['message'], 'bob and alice are now friends!');
      expect(note['uid1'], 'u2');
      expect(note['uid2'], 'u1');
      expect(note['inform'], ['carol']);
    });

    test('accepting with no friends to inform sends no notification', () async {
      await friend(firestore, 'u2', 'u1', 'bob', 'alice', [], true);

      final notes = await firestore.collection('Notifications').get();
      expect(notes.docs, isEmpty);
    });
  });
}
