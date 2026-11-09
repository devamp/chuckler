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

  test('created prompts follow the others, survive reloads, one a day',
      () async {
    final now = DateTime.utc(2026, 11, 8, 15);
    s.setPrompts([aPrompt('a')], [null]);
    expect(s.canCreatePrompt(now), isTrue);
    expect(s.creatorFor(0).uid, chucklerUid);

    final mine = await createFriendPrompt(
        FakeFirebaseFirestore(), DbUser('me', 'caden', 0, 0, ''), 'Hi', '');
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
}
