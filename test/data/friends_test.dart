// Characterization tests for lib/data/friends.dart.
//
// These describe what the queries do today, not what they should do. Where
// today's behavior looks like a bug, the test still matches it and carries a
// TODO so the bug can be fixed deliberately later.

import 'package:chuckler/data/friends.dart';
import 'package:chuckler/database/models.dart';
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

  group('friends by uid', () {
    final ava = DbUser('u-ava', 'ava', 0, 0, '');
    final ben = DbUser('u-ben', 'ben', 0, 0, '');

    setUp(() async {
      for (final u in [ava, ben]) {
        await firestore.doc('Users/${u.uid}').set(
            {'username': u.username, 'profileImage': ''});
        await firestore.doc('Usernames/${u.username}').set({'uid': u.uid});
      }
      await firestore.doc('Users/chuckler').set({'username': 'Chuckler'});
      await firestore.doc('Usernames/chuckler').set({'uid': 'chuckler'});
    });

    test('emailHash ignores case and spaces', () {
      expect(emailHash(' Ava@Chuckler.TEST '), emailHash('ava@chuckler.test'));
      expect(emailHash('ava@chuckler.test'), hasLength(64));
      expect(emailHash('ava@chuckler.test'),
          isNot(emailHash('ben@chuckler.test')));
    });

    test('findUserByUsername ignores case and refuses bad names', () async {
      expect((await findUserByUsername(firestore, 'BEN'))!.uid, 'u-ben');
      expect(await findUserByUsername(firestore, 'nobody'), isNull);
      expect(await findUserByUsername(firestore, 'a b'), isNull);
    });

    test('sendFriendRequest writes a card under the recipient', () async {
      expect(await sendFriendRequest(firestore, ava, 'ben'),
          FriendRequestResult.sent);
      final r = await firestore.doc('Users/u-ben/FriendRequests/u-ava').get();
      expect(r.data()!['username'], 'ava');
    });

    test('sendFriendRequest refuses unknown names, yourself, Chuckler, friends',
        () async {
      expect(await sendFriendRequest(firestore, ava, 'zed'),
          FriendRequestResult.notFound);
      expect(await sendFriendRequest(firestore, ava, 'Ava'),
          FriendRequestResult.isYou);
      expect(await sendFriendRequest(firestore, ava, 'chuckler'),
          FriendRequestResult.notAllowed);
      await firestore.doc('Users/u-ava/Friends/u-ben').set({'username': 'ben'});
      expect(await sendFriendRequest(firestore, ava, 'ben'),
          FriendRequestResult.alreadyFriends);
    });

    test('asking someone who already asked you makes you friends', () async {
      await sendFriendRequest(firestore, ben, 'ava');
      expect(await sendFriendRequest(firestore, ava, 'ben'),
          FriendRequestResult.accepted);
      expect((await getFriends(firestore, 'u-ava')).single.username, 'ben');
      expect((await getFriends(firestore, 'u-ben')).single.username, 'ava');
      expect(await getFriendRequests(firestore, 'u-ava', null), isEmpty);
    });

    test('email requests are found by the recipient\'s email', () async {
      await sendEmailFriendRequest(firestore, ben, 'AVA@chuckler.test');

      final reqs =
          await getFriendRequests(firestore, 'u-ava', 'ava@chuckler.test');
      expect(reqs.map((r) => r.username), ['ben']);
      expect(reqs.single.byEmail, isTrue);
      // without the email, only username requests show
      expect(await getFriendRequests(firestore, 'u-ava', null), isEmpty);
    });

    test('accepting an email request befriends both and removes it', () async {
      await sendEmailFriendRequest(firestore, ben, 'ava@chuckler.test');
      final r = (await getFriendRequests(
              firestore, 'u-ava', 'ava@chuckler.test'))
          .single;

      await acceptFriendRequest(firestore, ava, r,
          myEmail: 'ava@chuckler.test');

      expect((await getFriends(firestore, 'u-ben')).single.uid, 'u-ava');
      expect(
          await getFriendRequests(firestore, 'u-ava', 'ava@chuckler.test'),
          isEmpty);
    });

    test('declining removes only the request', () async {
      await sendFriendRequest(firestore, ben, 'ava');
      final r = (await getFriendRequests(firestore, 'u-ava', null)).single;
      await declineFriendRequest(firestore, 'u-ava', r);
      expect(await getFriendRequests(firestore, 'u-ava', null), isEmpty);
      expect(await getFriends(firestore, 'u-ava'), isEmpty);
    });

    test('removeFriend unfriends both sides; friends sort by name', () async {
      await firestore.doc('Users/u-ava/Friends/u-ben').set({'username': 'ben'});
      await firestore.doc('Users/u-ava/Friends/u-al').set({'username': 'Al'});
      await firestore.doc('Users/u-ben/Friends/u-ava').set({'username': 'ava'});
      expect((await getFriends(firestore, 'u-ava')).map((f) => f.username),
          ['Al', 'ben']);

      await removeFriend(firestore, 'u-ava', 'u-ben');

      expect((await getFriends(firestore, 'u-ava')).map((f) => f.username),
          ['Al']);
      expect(await getFriends(firestore, 'u-ben'), isEmpty);
    });
  });
}
