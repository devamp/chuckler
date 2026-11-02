// Characterization tests for lib/DatabaseQueries.dart.
//
// These describe what the queries do today, not what they should do. Where
// today's behavior looks like a bug, the test still matches it and carries a
// TODO so the bug can be fixed deliberately later.

import 'package:chuckler/DatabaseQueries.dart';
import 'package:chuckler/database/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Some queries fire writes without awaiting them; give those time to land.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

Map<String, dynamic> userDoc({
  String username = 'alice',
  int posts = 3,
  int friends = 0,
  int pendingFriends = 0,
  List<String>? friendsList,
  List<String>? pendingFriendsList,
  String profileImage = 'https://example.com/a.png',
}) {
  return {
    'username': username,
    'posts': posts,
    'friends': friends,
    'pendingFriends': pendingFriends,
    'profileImage': profileImage,
    if (friendsList != null) 'friendsList': friendsList,
    if (pendingFriendsList != null) 'pendingFriendsList': pendingFriendsList,
  };
}

Map<String, dynamic> postDoc({
  required String promptId,
  required String promptDateId,
  required DateTime date,
  String uid = 'u1',
  String username = 'alice',
  String answer = 'an answer',
}) {
  return {
    'answer': answer,
    'username': username,
    'uid': uid,
    'likes': 1,
    'dislikes': 2,
    'wins': 3,
    'promptId': promptId,
    'promptDateId': promptDateId,
    'date': Timestamp.fromDate(date),
  };
}

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  group('getDailyPrompts', () {
    final now = DateTime.now().toUtc();
    final todayNoon = DateTime.utc(now.year, now.month, now.day, 12);
    final todayId = todayNoon.toIso8601String().substring(0, 10);
    final yesterdayId = todayNoon
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    Future<DocumentReference> seedPromptDay(DateTime date) {
      return firestore
          .collection('PromptDays')
          .add({'date': Timestamp.fromDate(date)});
    }

    test('maps today\'s prompts from the Prompts subcollection', () async {
      final day = await seedPromptDay(todayNoon);
      await day.collection('Prompts').doc('p1').set(
          {'before': 'I like', 'after': 'a lot', 'type': 'fun', 'responses': 4});

      final prompts = await getDailyPrompts(firestore);

      expect(prompts, hasLength(1));
      final p = prompts.single;
      expect(p.before, 'I like');
      expect(p.after, 'a lot');
      expect(p.type, 'fun');
      expect(p.responses, 4);
      expect(p.promptId, 'p1');
      // promptDateId is the PromptDays document id
      expect(p.promptDateId, day.id);
      // TODO(bug): utcMidnight subtracts now.microsecond as milliseconds.
      // Whenever the microsecond part is larger than the millisecond part
      // (about half the time), "midnight" lands in the last second of the
      // previous day and date comes out as yesterday.
      expect(p.date, anyOf(todayId, yesterdayId));
      expect(isAwaitingPrompt(p), isFalse);
    });

    test('responses defaults to 0 when the field is missing', () async {
      final day = await seedPromptDay(todayNoon);
      await day
          .collection('Prompts')
          .doc('p1')
          .set({'before': 'a', 'after': 'b', 'type': 't'});

      final prompts = await getDailyPrompts(firestore);

      expect(prompts.single.responses, 0);
    });

    test('ignores PromptDays from other days', () async {
      final yesterday = await seedPromptDay(
          todayNoon.subtract(const Duration(days: 1)));
      await yesterday
          .collection('Prompts')
          .doc('old')
          .set({'before': 'a', 'after': 'b', 'type': 't'});

      final prompts = await getDailyPrompts(firestore);

      expect(prompts.single.promptId, awaitingPromptId);
    });

    test('returns the awaiting placeholder when there is no PromptDays doc',
        () async {
      final prompts = await getDailyPrompts(firestore);

      expect(prompts, hasLength(1));
      final p = prompts.single;
      expect(isAwaitingPrompt(p), isTrue);
      expect(p.promptId, awaitingPromptId);
      expect(p.promptDateId, awaitingPromptId);
      expect(p.before, 'The daily prompt is still');
      expect(p.after, 'in the oven. Check back soon!');
      expect(p.responses, 0);
      // null date keeps IsarService.getDailyPromptsFromDB from serving it
      expect(p.date, isNull);
    });

    test('returns the awaiting placeholder when today has no prompts',
        () async {
      await seedPromptDay(todayNoon);

      final prompts = await getDailyPrompts(firestore);

      expect(prompts.single.promptId, awaitingPromptId);
    });

    // TODO(bug): the same midnight error shifts the query window by up to a
    // second either way, and isLessThan 23:59:59 skips the day's last second.
    // Not tested here: the result depends on the exact moment DateTime.now()
    // runs.
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
      // TODO(bug): the update is not awaited, so callers cannot tell when it
      // lands and its errors escape.
      await firestore.collection('Users').doc('u1').set(userDoc(posts: 3));

      await incrementNumPosts(firestore, 'u1');
      await settle();

      final doc = await firestore.collection('Users').doc('u1').get();
      expect(doc.data()!['posts'], 4);
    });

    test('updateProfilePhoto sets profileImage', () async {
      await firestore.collection('Users').doc('u1').set(userDoc());

      await updateProfilePhoto(firestore, 'https://example.com/b.png', 'u1');

      final doc = await firestore.collection('Users').doc('u1').get();
      expect(doc.data()!['profileImage'], 'https://example.com/b.png');
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

  group('comments', () {
    test('addCommentToPost writes a comment for the post', () async {
      await addCommentToPost(firestore, 'post1', 'alice', 'lol');

      final comments = await firestore.collection('Comments').get();
      final c = comments.docs.single.data();
      expect(c['postId'], 'post1');
      expect(c['username'], 'alice');
      expect(c['comment'], 'lol');
      expect(c['date'], isA<Timestamp>());
    });

    test('getComments returns up to 5 comments for the post', () async {
      for (var i = 0; i < 7; i++) {
        await addCommentToPost(firestore, 'post1', 'user$i', 'comment $i');
      }
      await addCommentToPost(firestore, 'post2', 'zed', 'elsewhere');

      final comments = await getComments(firestore, 'post1');

      expect(comments, hasLength(5));
      expect(comments.every((c) => c.comment!.startsWith('comment ')), isTrue);
      expect(comments.first.username, startsWith('user'));
    });

    test('getComments returns an empty list when there are none', () async {
      expect(await getComments(firestore, 'post1'), isEmpty);
    });
  });

  group('awaiting prompt helpers', () {
    // CreatePageContent.postData returns early for this prompt, so nothing is
    // posted until today's prompt exists.
    test('isAwaitingPrompt only matches the placeholder', () {
      expect(isAwaitingPrompt(awaitingPrompt()), isTrue);
      expect(isAwaitingPrompt(DbPrompt('a', 'b', 'day1', 'p1', '2026-11-01', 't')),
          isFalse);
    });
  });
}
