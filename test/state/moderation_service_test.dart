// ModerationService: what it hides, and reporting, blocking and the
// content filter updating it right away.

import 'dart:io';

import 'package:chuckler/data/moderation.dart';
import 'package:chuckler/state/moderation_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore f;
  late ModerationService s;

  setUp(() async {
    f = FakeFirebaseFirestore();
    s = ModerationService(
        loadCategories: () async => parseWordList(
            File('functions/wordlist.json').readAsStringSync()));
    await f.doc('Users/u1/Blocked/u9').set(
        {'uid': 'u9', 'username': 'troll', 'photoUrl': ''});
    await f.doc('Users/u1/Private/reported').set({
      'matchupIds': ['m1'],
      'commentIds': ['c1'],
      'promptIds': ['p1'],
    });
    await f.doc('Users/u1/Private/blockedContent').set({
      'matchupIds': ['m2'],
    });
    await s.load(f, 'u1');
  });

  test('hides reported, blocked and filtered matchups', () {
    bool hides(String id, {String prompt = 'My ', String answer = 'a goose'}) =>
        s.hidesMatchup(id: id, prompt: prompt, answers: [answer, 'ok']);
    expect(hides('m1'), isTrue, reason: 'reported');
    expect(hides('m2'), isTrue, reason: "a blocked user's");
    expect(hides('m3'), isFalse);
    expect(hides('m3', answer: 'total slut'), isTrue, reason: 'filtered');
    expect(hides('m3', answer: 'what the fuck'), isFalse,
        reason: 'strong language is off by default');
  });

  test('hides comments from blocked people, reported ones and filtered text',
      () {
    bool hides(String id, String uid, String name, String text) =>
        s.hidesComment(id: id, uid: uid, username: name, text: text);
    expect(hides('c1', 'u2', 'ben', 'hi'), isTrue);
    expect(hides('c2', 'u9', 'troll', 'hi'), isTrue);
    expect(hides('c2', 'u5', 'TROLL', 'hi'), isTrue, reason: 'by username');
    expect(hides('c2', 'u2', 'ben', 'p0rn'), isTrue);
    expect(hides('c2', 'u2', 'ben', 'hi'), isFalse);
  });

  test('hides reported prompts and blocked creators', () {
    expect(s.hidesPrompt(id: 'p1', text: 'x'), isTrue);
    expect(s.hidesPrompt(id: 'p2', creatorUid: 'u9', text: 'x'), isTrue);
    expect(s.hidesPrompt(id: 'p2', creatorUid: 'u2', text: 'x'), isFalse);
  });

  test('usernames are checked against every category', () {
    expect(s.allowsUsername('goose_king'), isTrue);
    expect(s.allowsUsername('fuck_it'), isFalse);
  });

  test('reporting and blocking take effect at once', () async {
    var notified = 0;
    s.addListener(() => notified++);
    await s.report(f,
        reporter: 'u1',
        target: ReportTarget.answer,
        targetId: 'post5',
        postId: 'post5',
        matchupId: 'm5',
        reason: ReportReason.spam);
    expect(s.hidesMatchup(id: 'm5', prompt: '', answers: const []), isTrue);

    await s.block(f, 'u1', const BlockedUser('u2', 'ben'), matchupId: 'm6');
    expect(s.isBlocked('u2'), isTrue);
    expect(s.hidesMatchup(id: 'm6', prompt: '', answers: const []), isTrue);
    expect(s.blocked.map((b) => b.username), ['ben', 'troll']);

    await s.unblock(f, 'u1', 'u2');
    expect(s.isBlocked('u2'), isFalse);
    expect(notified, 3);
  });

  test('the content filter can be changed and is saved', () async {
    expect(s.contentFilter, {'slurs', 'sexual'});
    await s.setFiltered(f, 'u1', 'profanity', true);
    expect(s.filters('what the fuck'), isTrue);
    await s.setFiltered(f, 'u1', 'sexual', false);
    expect(s.filters('p0rn'), isFalse);
    expect(await getContentFilter(f, 'u1'), {'slurs', 'profanity'});
  });

  test('logout forgets everything', () {
    s.logout();
    expect(s.isBlocked('u9'), isFalse);
    expect(s.hidesMatchup(id: 'm1', prompt: '', answers: const []), isFalse);
    expect(s.loaded, isFalse);
  });
}
