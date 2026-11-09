// Tests for FriendsService, the state behind the Friends screen.

import 'package:chuckler/data/friends.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/state/friends_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FriendsService s;
  final ava = DbUser('u-ava', 'ava', 0, 0, '');

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    s = FriendsService();
    for (final (uid, name) in [('u-ava', 'ava'), ('u-ben', 'ben')]) {
      await firestore.doc('Users/$uid').set({'username': name});
      await firestore.doc('Usernames/$name').set({'uid': uid});
    }
  });

  test('load reads friends and both kinds of requests', () async {
    await firestore.doc('Users/u-ava/Friends/u-cleo').set({'username': 'cleo'});
    await firestore
        .doc('Users/u-ava/FriendRequests/u-ben')
        .set({'username': 'ben'});
    await firestore
        .doc('EmailRequests/${emailHash('ava@chuckler.test')}/From/u-dev')
        .set({'username': 'dev'});

    await s.load(firestore, 'u-ava', 'ava@chuckler.test');

    expect(s.loaded, isTrue);
    expect(s.friendCount, 1);
    expect(s.pendingCount, 2);
  });

  test('send picks email or username from the input', () async {
    expect(await s.send(firestore, ava, 'someone@example.com', null),
        FriendRequestResult.sent);
    expect(
        (await firestore
                .doc(
                    'EmailRequests/${emailHash('someone@example.com')}/From/u-ava')
                .get())
            .exists,
        isTrue);
    expect(
        await s.send(firestore, ava, ' ben ', null), FriendRequestResult.sent);
    expect(
        await s.send(firestore, ava, 'AVA@chuckler.test', 'ava@chuckler.test'),
        FriendRequestResult.isYou);
  });

  test('accept moves a request into friends; decline drops it', () async {
    await firestore
        .doc('Users/u-ava/FriendRequests/u-ben')
        .set({'username': 'ben'});
    await firestore
        .doc('Users/u-ava/FriendRequests/u-cleo')
        .set({'username': 'cleo'});
    await s.load(firestore, 'u-ava', null);

    await s.accept(
        firestore, ava, s.requests.firstWhere((r) => r.uid == 'u-ben'), null);
    expect(s.friends.map((f) => f.username), ['ben']);
    expect(s.pendingCount, 1);

    await s.decline(firestore, 'u-ava', s.requests.single, null);
    expect(s.pendingCount, 0);
    expect(s.friendCount, 1);
  });

  test('remove and logout clear friends', () async {
    await firestore.doc('Users/u-ava/Friends/u-ben').set({'username': 'ben'});
    await s.load(firestore, 'u-ava', null);
    await s.remove(firestore, 'u-ava', s.friends.single);
    expect(s.friendCount, 0);

    await s.load(firestore, 'u-ava', null);
    s.logout();
    expect(s.loaded, isFalse);
  });
}
