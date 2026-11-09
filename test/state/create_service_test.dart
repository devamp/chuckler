// Tests for CreateService, the state behind the Create tab.

import 'package:chuckler/data/friend_prompts.dart';
import 'package:chuckler/data/prompts.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/state/create_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

DbPrompt aPrompt(String id) => DbPrompt('before ', '', 'day-1', id, null, null);

DbPost aPost(String promptId, String answer) =>
    DbPost('post-$promptId', answer, 'caden', 'me', 0, 0, 0, promptId, 'day-1');

void main() {
  late CreateService s;
  setUp(() => s = CreateService());

  test('pairs live prompts with their posts', () {
    s.setPrompts([aPrompt('a'), aPrompt('b')], [aPost('a', 'hi')]);

    expect(s.length, 2);
    expect(s.postFor(0)?.answer, 'hi');
    expect(s.answered(1), isFalse);
    expect(s.answeredCount, 1);
    expect(s.answerableCount, 2);
  });

  test('sample prompts follow live ones only when asked for', () {
    s.setPrompts([awaitingPrompt()], [null]);
    expect(s.length, 1);
    expect(s.answerableCount, 0);

    s.setPrompts([awaitingPrompt()], [null], includeSamples: true, uid: 'me');
    expect(s.length, 4);
    expect(s.answerableCount, 3);
    // one sample starts out answered, by the logged-in user
    expect(s.answeredCount, 1);
    expect(s.postFor(2)?.uid, 'me');
  });

  test('drafts and sample answers survive a reload', () {
    s.setPrompts([awaitingPrompt()], [null], includeSamples: true);
    s.setDraft(1, 'half done');
    s.markPosted(3, aPost('sample-bus', 'traffic'));

    s.setPrompts([awaitingPrompt()], [null], includeSamples: true);

    expect(s.draftFor(1), 'half done');
    expect(s.postFor(3)?.answer, 'traffic');
    expect(s.answeredCount, 2);
  });

  test('posting clears the draft', () {
    s.setPrompts([aPrompt('a')], [null]);
    s.setDraft(0, 'almost');
    s.markPosted(0, aPost('a', 'done'));

    expect(s.draftFor(0), '');
    expect(s.answered(0), isTrue);
  });

  test('setPage ignores out-of-range pages, and a shorter list resets it', () {
    s.setPrompts([aPrompt('a'), aPrompt('b'), aPrompt('c')], []);
    s.setPage(2);
    s.setPage(7);
    expect(s.page, 2);

    s.setPrompts([aPrompt('a')], []);
    expect(s.page, 0);
  });

  test('loadStats fills stats for every prompt but the placeholder', () async {
    s.setPrompts([awaitingPrompt(), aPrompt('a')], [null, null]);
    await s.loadStats(FakeFirebaseFirestore(), 'me');

    expect(s.statsFor(0), isNull);
    expect(s.statsFor(1), isNotNull);
  });

  test('likes count the user once, however often they toggle', () async {
    s.setPrompts([aPrompt('a')], [null]);
    expect(s.likesFor(0), 0);
    await s.loadStats(FakeFirebaseFirestore(), 'me');
    final base = s.likesFor(0);

    expect(s.toggleLike(0), isTrue);
    expect(s.likesFor(0), base + 1);
    expect(s.toggleLike(0), isFalse);
    expect(s.likesFor(0), base);
  });

  test('created prompts follow the daily ones, survive reloads, one a day',
      () async {
    final now = DateTime.utc(2026, 11, 8, 15);
    s.setPrompts([aPrompt('a')], [null]);
    expect(s.canCreatePrompt(now), isTrue);
    expect(s.creatorFor(0).uid, chucklerUid);

    final mine = await createFriendPrompt(FakeFirebaseFirestore(),
        DbUser('me', 'caden', 0, 0, ''), 'Hi', '', '2026-11-08');
    const me = PromptCreator(uid: 'me', username: 'caden');
    expect(s.addCreatedPrompt(mine, me, now), 1);
    expect(s.page, 1);
    expect(s.creatorFor(1).username, 'caden');
    expect(s.canCreatePrompt(now), isFalse);
    expect(s.canCreatePrompt(now.add(const Duration(days: 1))), isTrue);

    s.markPosted(1, aPost(mine.promptId!, 'answer'));
    s.setPrompts([aPrompt('a')], [null]);
    expect(s.length, 2);
    expect(s.postFor(1)?.answer, 'answer');
    expect(s.creatorFor(1).username, 'caden');
  });

  test('logout clears everything', () async {
    s.setPrompts([awaitingPrompt()], [null], includeSamples: true);
    s.setDraft(1, 'x');
    await s.loadStats(FakeFirebaseFirestore(), 'me');
    await s.loadStats(FakeFirebaseFirestore(), 'me');
    s.addCreatedPrompt(aPrompt('mine'),
        const PromptCreator(uid: 'me', username: 'caden'), DateTime.utc(2026));
    s.logout();

    expect(s.length, 0);
    expect(s.canCreatePrompt(DateTime.utc(2026)), isTrue);
    expect(s.streak, 0);
    s.setPrompts([awaitingPrompt()], [null], includeSamples: true);
    expect(s.draftFor(1), '');
  });

  group('answer count after posting', () {
    late FakeFirebaseFirestore firestore;
    final prompt = DbPrompt('before ', '', '2026-11-08', 'p1', null, null);

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await firestore.doc('PromptDays/2026-11-08/Prompts/p1').set({
        'counts': {'answers': 8, 'likes': 0},
      });
      s.setPrompts([prompt], [null]);
      await s.loadStats(firestore, 'me');
    });

    test('counts the user\'s answer before the server does', () async {
      s.markPosted(0, aPost('p1', 'hi'));
      await s.loadStats(firestore, 'me', only: 0, justAnswered: true);
      expect(s.statsFor(0)!.answers, 9);
    });

    test('uses the server count once it has caught up', () async {
      await firestore
          .doc('PromptDays/2026-11-08/Prompts/p1')
          .update({'counts.answers': 10});
      s.markPosted(0, aPost('p1', 'hi'));
      await s.loadStats(firestore, 'me', only: 0, justAnswered: true);
      expect(s.statsFor(0)!.answers, 10);
    });

    test('a plain reload shows the server count', () async {
      await s.loadStats(firestore, 'me', only: 0);
      expect(s.statsFor(0)!.answers, 8);
    });
  });

  test('friend prompts come after the daily ones and before samples', () {
    final now = DateTime.utc(2026, 11, 8, 15);
    s.setPrompts([aPrompt('a')], [null], includeSamples: true);
    final theirs = friendPromptFromDoc('ben_2026-11-08', {
      'before': 'Ben asks ', 'after': '.', 'dayId': '2026-11-08',
      'creator': {'uid': 'ben', 'username': 'ben', 'photoUrl': ''},
    });
    s.setPage(2);
    final shown = s.current!.promptId;
    s.setFriendPrompts([theirs], {'ben_2026-11-08': aPost('ben_2026-11-08', 'hi')},
        uid: 'me', nowUtc: now);
    expect(s.prompts[1].promptId, 'ben_2026-11-08');
    expect(isFriendPrompt(s.prompts[1]), isTrue);
    expect(s.postFor(1)?.answer, 'hi');
    expect(s.creatorFor(1).username, 'ben');
    expect(s.length, 5); // a, ben's, 3 samples
    expect(s.current!.promptId, shown); // stays on the same prompt
    // someone else's prompt doesn't use up the user's one a day
    expect(s.canCreatePrompt(now), isTrue);

    final mine = friendPromptFromDoc('me_2026-11-08', {
      'before': 'Mine ', 'after': '', 'dayId': '2026-11-08',
      'creator': {'uid': 'me', 'username': 'caden', 'photoUrl': ''},
    });
    s.setFriendPrompts([theirs, mine], {}, uid: 'me', nowUtc: now);
    expect(s.canCreatePrompt(now), isFalse);
    expect(s.postFor(1), isNull);
  });
}
