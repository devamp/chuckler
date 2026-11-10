// Moderation data: the word filter (twin of functions/moderation.js),
// reports, blocks and what to hide, against a fake Firestore.

import 'dart:io';

import 'package:chuckler/data/moderation.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categories =
      parseWordList(File('functions/wordlist.json').readAsStringSync());
  final all = wordsIn(categories);

  group('word list', () {
    test('has the three categories, slurs and sexual on by default', () {
      expect(categories.map((c) => c.id), ['slurs', 'sexual', 'profanity']);
      expect(defaultContentFilter(categories), {'slurs', 'sexual'});
      expect(categories.every((c) => c.words.isNotEmpty), isTrue);
    });

    test('catches listed words, plurals and letter swaps', () {
      for (final bad in ['you are a slut', 'SLUTS everywhere', 'p0rn',
          'what a wh0re!', 'k y s']) {
        expect(containsBlockedWords(bad, all), isTrue, reason: bad);
      }
    });

    test('leaves ordinary words alone (same cases as the functions)', () {
      for (final ok in ['class', 'Scunthorpe', 'grape', 'therapist',
          'analysis', 'cocktail', 'Moby Dick', 'raccoon', 'hell yeah',
          "damn that's good", 'a cumulative score', '']) {
        expect(containsBlockedWords(ok, all), isFalse, reason: ok);
      }
    });

    test('only checks the categories it is given', () {
      final profanity = wordsIn(categories.where((c) => c.id == 'profanity'));
      expect(containsBlockedWords('what the fuck', profanity), isTrue);
      expect(containsBlockedWords('what the fuck',
          wordsIn(categories.where((c) => c.id != 'profanity'))), isFalse);
    });
  });

  group('reports', () {
    test('write a report and hide the thing for the reporter', () async {
      final f = FakeFirebaseFirestore();
      await reportContent(f,
          reporter: 'u1',
          target: ReportTarget.answer,
          targetId: 'post1',
          postId: 'post1',
          matchupId: 'm1',
          reason: ReportReason.offensive);
      await reportContent(f,
          reporter: 'u1',
          target: ReportTarget.comment,
          targetId: 'c1',
          postId: 'post1',
          reason: ReportReason.spam);
      final reports = await f.collection('Reports').get();
      expect(reports.docs.map((d) => d.data()['targetType']),
          containsAll(['answer', 'comment']));
      final answer = reports.docs
          .firstWhere((d) => d.data()['targetType'] == 'answer')
          .data();
      expect(answer['reporter'], 'u1');
      expect(answer['reason'], 'offensive');
      expect(answer['matchupId'], 'm1');

      final state = await getModerationState(f, 'u1');
      expect(state.reportedMatchups, {'m1'});
      expect(state.reportedComments, {'c1'});
    });
  });

  group('blocking', () {
    test('block, list and unblock', () async {
      final f = FakeFirebaseFirestore();
      await blockUser(f, 'u1', const BlockedUser('u2', 'ben'));
      await blockUser(f, 'u1', const BlockedUser('u3', 'Ava'));
      expect((await getBlocked(f, 'u1')).map((b) => b.username),
          ['Ava', 'ben']);
      final doc = await f.doc('Users/u1/Blocked/u2').get();
      expect(doc.data()!['uid'], 'u2');
      await unblockUser(f, 'u1', 'u2');
      expect((await getBlocked(f, 'u1')).map((b) => b.uid), ['u3']);
    });

    test("the server's list of blocked users' matchups is read", () async {
      final f = FakeFirebaseFirestore();
      await f.doc('Users/u1/Private/blockedContent').set({
        'matchupIds': ['m7', 'm8'],
      });
      expect((await getModerationState(f, 'u1')).blockedMatchups,
          {'m7', 'm8'});
    });

    test('usernames and uids look each other up', () async {
      final f = FakeFirebaseFirestore();
      await f.doc('Usernames/ben').set({'uid': 'u2'});
      await f.doc('Users/u2').set({'username': 'Ben'});
      expect(await uidForUsername(f, 'BEN'), 'u2');
      expect(await usernameForUid(f, 'u2'), 'Ben');
      expect(await uidForUsername(f, 'nobody'), isNull);
    });
  });

  test('the content filter setting saves and reads', () async {
    final f = FakeFirebaseFirestore();
    expect(await getContentFilter(f, 'u1'), isNull);
    await saveContentFilter(f, 'u1', {'profanity', 'slurs'});
    expect(await getContentFilter(f, 'u1'), {'profanity', 'slurs'});
  });
}
