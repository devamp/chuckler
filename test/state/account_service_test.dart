import 'dart:io';

import 'package:chuckler/data/awards.dart';
import 'package:chuckler/state/account_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<AwardTrack>> fileCatalog() async =>
    parseAwardCatalog(File('functions/awards.json').readAsStringSync());

final now = DateTime.utc(2026, 11, 9, 12);

void main() {
  late FakeFirebaseFirestore firestore;
  late AccountService account;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    account = AccountService(loadCatalog: fileCatalog);
    await firestore.doc('Users/u1/FriendView/profile').set({
      'stats': {'answers': 2, 'wins': 5},
      'streak': {'days': '1', 'from': '2026-09-15', 'longest': 1},
      'awards': {
        'posts': {'1': Timestamp.now()},
      },
    });
    await firestore.doc('Users/u1/History/2026-11').set({
      'answers': {
        '2026-11-09_p1': {
          'postId': 'p',
          'promptDateId': '2026-11-09',
          'promptId': 'p1',
          'answer': 'hi',
        },
      },
    });
    for (final id in ['a', 'b']) {
      await firestore.doc('Users/u1/Notifications/$id').set({
        'type': 'award',
        'text': id,
        'at': Timestamp.now(),
        'seen': id == 'a',
      });
    }
  });

  test('loads the profile, answers, notifications and awards', () async {
    expect(account.loaded, isFalse);
    await account.load(firestore, 'u1', now: now);
    expect(account.loaded, isTrue);
    expect(account.profile.answers, 2);
    expect(account.profile.wins, 5);
    expect(account.answers.single.answer, 'hi');
    // first answer in September: November and October are read first
    expect(account.hasMoreAnswers, isTrue);
    await account.loadMoreAnswers(firestore, 'u1');
    expect(account.answers.single.answer, 'hi');
    expect(account.hasMoreAnswers, isFalse);
    expect(account.notifications.length, 2);
    expect(account.unseenCount, 1);
    final posts = account.awards.firstWhere((a) => a.track.id == 'posts');
    expect(posts.latest!.name, 'First Post');
  });

  test('marking all seen clears the count and saves it', () async {
    await account.load(firestore, 'u1', now: now);
    await account.markAllSeen(firestore, 'u1');
    expect(account.unseenCount, 0);
    final b = await firestore.doc('Users/u1/Notifications/b').get();
    expect(b.data()!['seen'], isTrue);
  });

  test('a catalog that fails to load leaves awards empty', () async {
    account = AccountService(loadCatalog: () async => throw 'no asset');
    await account.load(firestore, 'u1', now: now);
    expect(account.loaded, isTrue);
    expect(account.awards, isEmpty);
    expect(account.profile.answers, 2);
  });

  test('logout clears everything', () async {
    await account.load(firestore, 'u1', now: now);
    account.logout();
    expect(account.loaded, isFalse);
    expect(account.answers, isEmpty);
    expect(account.notifications, isEmpty);
    expect(account.profile.answers, 0);
  });
}
