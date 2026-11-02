// Characterization tests for the session, prompt and feed services. They were
// written against UserService before it was split, and the assertions are
// unchanged.

import 'package:chuckler/state/feed_service.dart';
import 'package:chuckler/state/prompt_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/database/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DbUser aUser() => DbUser('u1', 'alice', 2, 3, 'pic');
DbPrompt aPrompt(String id) => DbPrompt('b', 'a', 'day1', id, '2026-11-01', 't');
DbPost aPost(String id) => DbPost(id, 'ans', 'alice', 'u1', 0, 0, 0, 'p1', 'day1');

void main() {
  late int notified;

  setUp(() {
    notified = 0;
  });

  group('session', () {
    late SessionService s;

    setUp(() {
      s = SessionService();
      s.addListener(() => notified++);
    });

    test('starts with no user and no login time', () {
      expect(s.loggedInUser, isNull);
      expect(s.logTime, isNull);
      expect(s.firstLogin, isFalse);
    });

    test('setLoggedInUser stores the user and notifies', () {
      final u = aUser();
      s.setLoggedInUser(u);
      expect(s.loggedInUser, same(u));
      expect(notified, 1);
    });

    test('setUserProfilePicture and setUserFriends edit the user and notify', () {
      s.setLoggedInUser(aUser());
      s.setUserProfilePicture('new-pic');
      s.setUserFriends(5);
      expect(s.loggedInUser!.profilePicture, 'new-pic');
      expect(s.loggedInUser!.numFriends, 5);
      expect(notified, 3);
    });

    test('setLoginTime with a time keeps firstLogin false', () {
      s.setLoginTime('2026-11-01T00:00:00Z');
      expect(s.logTime, '2026-11-01T00:00:00Z');
      expect(s.firstLogin, isFalse);
      expect(notified, 1);
    });

    test('setLoginTime(null) sets firstLogin, and it stays set', () {
      s.setLoginTime(null);
      expect(s.firstLogin, isTrue);
      s.setLoginTime('2026-11-01T00:00:00Z');
      expect(s.firstLogin, isTrue);
    });
  });

  group('prompts', () {
    late PromptService s;

    setUp(() {
      s = PromptService();
      s.addListener(() => notified++);
    });

    test('start empty', () {
      expect(s.prompts, isEmpty);
      expect(s.userPostsForPrompts, isEmpty);
    });

    test('addPrompt and addPostForPrompt append and notify', () {
      s.addPrompt(aPrompt('p1'));
      s.addPostForPrompt(null);
      s.addPostForPrompt(aPost('x'));
      expect(s.prompts!.map((p) => p.promptId), ['p1']);
      expect(s.userPostsForPrompts.map((p) => p?.postId), [null, 'x']);
      expect(notified, 3);
    });

    test('clearPrompts empties prompts without notifying', () {
      s.addPrompt(aPrompt('p1'));
      notified = 0;
      s.clearPrompts();
      expect(s.prompts, isEmpty);
      expect(notified, 0);
    });

    test('clearPostsForPrompts empties posts and notifies', () {
      s.addPostForPrompt(aPost('x'));
      notified = 0;
      s.clearPostsForPrompts();
      expect(s.userPostsForPrompts, isEmpty);
      expect(notified, 1);
    });

    test('logout clears prompts and posts and notifies twice', () {
      s.addPrompt(aPrompt('p1'));
      s.addPostForPrompt(aPost('x'));
      notified = 0;
      s.logout();
      expect(s.prompts, isEmpty);
      expect(s.userPostsForPrompts, isEmpty);
      // once from clearPostsForPrompts, once from logout itself
      expect(notified, 2);
    });
  });

  group('feed', () {
    late FeedService s;

    setUp(() {
      s = FeedService();
      s.addListener(() => notified++);
    });

    test('starts with no posts, no prompt id and default viewing state', () {
      expect(s.currentPosts, isEmpty);
      expect(s.currentFeedPromptId, isNull);
      expect(s.viewingPost, '____________');
      expect(s.viewingColor, Colors.amber);
    });

    test('setters store values and notify', () {
      final posts = [aPost('a')];
      s.setCurrentPosts(posts);
      s.setCurrentFeedPromptId('p1');
      s.setViewingPost('an answer');
      s.setViewingColor(Colors.red);
      expect(s.currentPosts, same(posts));
      expect(s.currentFeedPromptId, 'p1');
      expect(s.viewingPost, 'an answer');
      expect(s.viewingColor, Colors.red);
      expect(notified, 4);
    });

    test('clearviewingPost and clearViewingColor restore defaults and notify', () {
      s.setViewingPost('an answer');
      s.setViewingColor(Colors.red);
      notified = 0;
      s.clearviewingPost();
      s.clearViewingColor();
      expect(s.viewingPost, '____________');
      expect(s.viewingColor, Colors.amber);
      expect(notified, 2);
    });
  });

  test('logout leaves the user, login time and feed in place', () {
    final session = SessionService();
    final prompts = PromptService();
    final feed = FeedService();
    // TODO(bug): logging out keeps the previous user's session and feed
    // state; only prompts and the user's posts are cleared.
    final u = aUser();
    session.setLoggedInUser(u);
    session.setLoginTime('2026-11-01T00:00:00Z');
    feed.setCurrentPosts([aPost('a')]);
    feed.setCurrentFeedPromptId('p1');
    prompts.logout();
    expect(session.loggedInUser, same(u));
    expect(session.logTime, '2026-11-01T00:00:00Z');
    expect(feed.currentPosts, hasLength(1));
    expect(feed.currentFeedPromptId, 'p1');
  });
}
