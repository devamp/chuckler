// Characterization tests for lib/data/posts.dart.
//
// These describe what the queries do today, not what they should do. Where
// today's behavior looks like a bug, the test still matches it and carries a
// TODO so the bug can be fixed deliberately later.

import 'package:chuckler/data/posts.dart';
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

  group('createPost', () {
    test('writes a post and returns it marked as mine', () async {
      final user = DbUser('u1', 'alice', 0, 0, '');
      final prompt =
          DbPrompt('before ', '', '2026-11-08', 'p1', '2026-11-08', null);

      final post = await createPost(firestore, user, prompt, 'my answer');

      expect(post.postId, isNotEmpty);
      expect(post.answer, 'my answer');
      expect(post.username, 'alice');
      expect(post.uid, 'u1');
      expect([post.likes, post.dislikes, post.wins], [0, 0, 0]);
      expect(post.promptId, 'p1');
      expect(post.promptDateId, '2026-11-08');
      expect(post.mine, isTrue);

      final doc = await firestore.collection('Posts').doc(post.postId).get();
      final data = doc.data()!;
      expect(data['answer'], 'my answer');
      expect(data['uid'], 'u1');
      expect(data['username'], 'alice');
      expect(data['promptId'], 'p1');
      expect(data['promptDateId'], '2026-11-08');
      expect([data['likes'], data['dislikes'], data['wins']], [0, 0, 0]);
      expect(data['random'], isA<int>());
      expect(data['date'], isA<Timestamp>());
      expect(data['before'], 'before ');
      expect(data['status'], 'active');
      expect(data['counts'],
          {'matchups': 0, 'votes': 0, 'wins': 0, 'dislikes': 0});

      // the same batch adds it to the user's History for that month
      final history = await firestore
          .collection('Users')
          .doc('u1')
          .collection('History')
          .doc('2026-11')
          .get();
      final entry = history.data()!['answers']['2026-11-08_p1'];
      expect(entry['postId'], post.postId);
      expect(entry['answer'], 'my answer');
      expect(entry['before'], 'before ');
    });

    test('a second answer in the month is added to the same History doc',
        () async {
      final user = DbUser('u1', 'alice', 0, 0, '');
      await createPost(firestore, user,
          DbPrompt('a', '', '2026-11-08', 'p1', '2026-11-08', null), 'one');
      await createPost(firestore, user,
          DbPrompt('b', '', '2026-11-09', 'p2', '2026-11-09', null), 'two');

      final history = await firestore
          .collection('Users')
          .doc('u1')
          .collection('History')
          .doc('2026-11')
          .get();
      expect((history.data()!['answers'] as Map).keys,
          containsAll(['2026-11-08_p1', '2026-11-09_p2']));
    });

    test('getMyAnswersForDay reads one day\'s answers from History',
        () async {
      final user = DbUser('u1', 'alice', 0, 0, '');
      final p1 = await createPost(firestore, user,
          DbPrompt('a', '', '2026-11-08', 'p1', '2026-11-08', null), 'one');
      await createPost(firestore, user,
          DbPrompt('b', '', '2026-11-07', 'p2', '2026-11-07', null), 'old');

      final mine = await getMyAnswersForDay(firestore, user, '2026-11-08');

      expect(mine.keys, ['p1']);
      expect(mine['p1']!.postId, p1.postId);
      expect(mine['p1']!.answer, 'one');
      expect(mine['p1']!.mine, isTrue);
      expect(await getMyAnswersForDay(firestore, user, '2026-12-01'), isEmpty);
    });
  });

  group('getPosts', () {
    final old = DateTime.utc(2020, 1, 1);

    test('returns posts for the prompt, mapped to DbPost', () async {
      await firestore.collection('Posts').doc('a').set(
          postDoc(promptId: 'p1', promptDateId: 'day1', date: old));
      await firestore.collection('Posts').doc('other-prompt').set(
          postDoc(promptId: 'p2', promptDateId: 'day1', date: old));
      await firestore.collection('Posts').doc('other-day').set(
          postDoc(promptId: 'p1', promptDateId: 'day2', date: old));

      final posts = await getPosts(firestore, 'p1', 'day1');

      expect(posts, hasLength(1));
      final p = posts.single;
      expect(p.postId, 'a');
      expect(p.answer, 'an answer');
      expect(p.username, 'alice');
      expect(p.uid, 'u1');
      expect([p.likes, p.dislikes, p.wins], [1, 2, 3]);
      expect(p.promptId, 'p1');
      expect(p.promptDateId, 'day1');
      expect(p.mine, isFalse);
    });

    test('returns at most 10 posts', () async {
      for (var i = 0; i < 12; i++) {
        await firestore.collection('Posts').add(
            postDoc(promptId: 'p1', promptDateId: 'day1', date: old));
      }

      final posts = await getPosts(firestore, 'p1', 'day1');

      expect(posts, hasLength(10));
    });

    test('prefers posts made since the last login', () async {
      SharedPreferences.setMockInitialValues(
          {'lastLoginTime': DateTime.utc(2025, 1, 1).toIso8601String()});
      await firestore.collection('Posts').doc('before-login').set(
          postDoc(promptId: 'p1', promptDateId: 'day1', date: old));
      await firestore.collection('Posts').doc('after-login').set(postDoc(
          promptId: 'p1', promptDateId: 'day1', date: DateTime.utc(2025, 6, 1)));

      final posts = await getPosts(firestore, 'p1', 'day1');

      expect(posts.map((p) => p.postId), ['after-login']);
    });

    test('falls back to any posts when none are newer than the last login',
        () async {
      SharedPreferences.setMockInitialValues(
          {'lastLoginTime': DateTime.utc(2025, 1, 1).toIso8601String()});
      await firestore.collection('Posts').doc('before-login').set(
          postDoc(promptId: 'p1', promptDateId: 'day1', date: old));

      final posts = await getPosts(firestore, 'p1', 'day1');

      expect(posts.map((p) => p.postId), ['before-login']);
    });

    test('returns an empty list when the prompt has no posts', () async {
      expect(await getPosts(firestore, 'p1', 'day1'), isEmpty);
    });
  });

  group('getUserPostForPrompt', () {
    test('returns the user\'s post for the prompt', () async {
      await firestore.collection('Posts').doc('mine').set(postDoc(
          promptId: 'p1', promptDateId: 'day1', date: DateTime.utc(2025)));
      await firestore.collection('Posts').doc('theirs').set(postDoc(
          promptId: 'p1',
          promptDateId: 'day1',
          date: DateTime.utc(2025),
          uid: 'u2'));

      final post = await getUserPostForPrompt(firestore, 'u1', 'day1', 'p1');

      expect(post, isNotNull);
      expect(post!.postId, 'mine');
      expect(post.uid, 'u1');
      expect(post.promptId, 'p1');
      expect(post.promptDateId, 'day1');
    });

    test('returns null when the user has not posted', () async {
      // TODO(bug): this only returns null because docs.first throws before the
      // isEmpty check and the catch turns the StateError into null.
      final post = await getUserPostForPrompt(firestore, 'u1', 'day1', 'p1');

      expect(post, isNull);
    });
  });

  group('post updates', () {
    setUp(() async {
      await firestore.collection('Posts').doc('post1').set(postDoc(
          promptId: 'p1', promptDateId: 'day1', date: DateTime.utc(2025)));
    });

    test('likeAPost adds a like and notifies the owner', () async {
      // TODO(bug): neither write is awaited, so errors skip the try/catch.
      await likeAPost(firestore, 'liker', 'post1', 'owner');
      await settle();

      final post = await firestore.collection('Posts').doc('post1').get();
      expect(post.data()!['likes'], 2);

      final notes = await firestore.collection('Notifications').get();
      expect(notes.docs, hasLength(1));
      final note = notes.docs.single.data();
      // TODO(bug): like notifications use a string type, friend ones use 0
      expect(note['type'], 'like');
      expect(note['postId'], 'post1');
      expect(note['liker'], 'liker');
      expect(note['notify'], ['owner']);
      expect(note['date'], isA<Timestamp>());
    });

    test('postWin adds a win', () async {
      await postWin(firestore, 'post1');

      final post = await firestore.collection('Posts').doc('post1').get();
      expect(post.data()!['wins'], 4);
    });
  });
}
