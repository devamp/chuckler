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
      final prompt = DbPrompt('before', 'after', 'day1', 'p1', '2026-11-01', 't');

      final post = await createPost(firestore, user, prompt, 'my answer');

      expect(post.postId, isNotEmpty);
      expect(post.answer, 'my answer');
      expect(post.username, 'alice');
      expect(post.uid, 'u1');
      expect([post.likes, post.dislikes, post.wins], [0, 0, 0]);
      expect(post.promptId, 'p1');
      expect(post.promptDateId, 'day1');
      expect(post.mine, isTrue);

      final doc = await firestore.collection('Posts').doc(post.postId).get();
      final data = doc.data()!;
      expect(data['answer'], 'my answer');
      expect(data['uid'], 'u1');
      expect(data['username'], 'alice');
      expect(data['promptId'], 'p1');
      expect(data['promptDateId'], 'day1');
      expect([data['likes'], data['dislikes'], data['wins']], [0, 0, 0]);
      expect(data['random'], isA<int>());
      expect(data['date'], isA<Timestamp>());
    });

    // TODO(bug): if the write fails, createPost still returns a DbPost with an
    // empty postId instead of reporting the failure. Not reproducible with the
    // fake, which never fails writes.
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
