// Tests for lib/data/matchups.dart against fake_cloud_firestore. The rules
// that refuse bad votes are covered by functions/test/rules.test.js.

import 'package:chuckler/data/matchups.dart';
import 'package:chuckler/data/prompt_day.dart';
import 'package:chuckler/data/sample_matchups.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  final now = DateTime.utc(2026, 11, 8, 18);
  final today = promptDayId(now);

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    await seedMatchups(firestore, sampleMatchups(), now: now);
  });

  group('getVotingMatchups', () {
    test('returns today\'s matchups oldest first', () async {
      final ms = await getVotingMatchups(firestore, 'me', {}, now: now);
      expect(ms.map((m) => m.id),
          ['sample-1', 'sample-2', 'sample-3', 'sample-4', 'sample-5']);
      final m = ms.first;
      expect(m.promptBefore, startsWith('The last thing'));
      expect(m.segment, Segment.global);
      expect(m.answers[0].postId, 's1a');
      expect(m.answers[0].wins, 31);
      expect(m.answers[1].downvotes, 4);
      expect(ms[1].segment, Segment.friends);
    });

    test('leaves out other days', () async {
      await firestore.collection('MatchUps').doc('old').set(matchupDoc(
          sampleMatchups().first,
          dayId: '2026-11-07',
          createdAt: now.subtract(const Duration(days: 1))));
      final ms = await getVotingMatchups(firestore, 'me', {}, now: now);
      expect(ms.map((m) => m.id), isNot(contains('old')));
    });

    test('leaves out matchups with my answers and ones I voted on', () async {
      await firestore.collection('Votes').doc('sample-3_me').set(
          {'uid': 'me', 'matchupId': 'sample-3', 'promptDateId': today});
      // someone else's vote doesn't hide it for me
      await firestore.collection('Votes').doc('sample-4_bob').set(
          {'uid': 'bob', 'matchupId': 'sample-4', 'promptDateId': today});

      final ms = await getVotingMatchups(firestore, 'me', {'s1b'}, now: now);

      expect(ms.map((m) => m.id), ['sample-2', 'sample-4', 'sample-5']);
    });

    test('skips docs without two answers', () async {
      await firestore.collection('MatchUps').doc('broken').set({
        'promptDateId': today,
        'createdAt': Timestamp.fromDate(now),
        'answers': [
          {'postId': 'x'}
        ],
      });
      final ms = await getVotingMatchups(firestore, 'me', {}, now: now);
      expect(ms, hasLength(5));
    });

    test('reads comment counts and previews', () async {
      await firestore.collection('MatchUps').doc('sample-1').update({
        'answers': [
          {
            'postId': 's1a',
            'answer': 'a',
            'commentCount': 3,
            'preview': [
              {'username': 'ben', 'text': 'lol'},
              {'username': 'cleo', 'text': 'stop'},
            ],
          },
          {'postId': 's1b', 'answer': 'b'},
        ],
      });
      final m = (await getVotingMatchups(firestore, 'me', {}, now: now)).first;
      expect(m.answers[0].commentCount, 3);
      expect(m.answers[0].preview.map((p) => '${p.username}: ${p.text}'),
          ['ben: lol', 'cleo: stop']);
      expect(m.answers[1].commentCount, 0);
      expect(m.answers[1].preview, isEmpty);
    });
  });

  group('castVote', () {
    test('a win writes one vote doc', () async {
      final m = sampleMatchups().first;
      await castVote(firestore, 'me', m, const MatchupVote(1, VoteType.win));

      final vote = (await firestore.doc('Votes/sample-1_me').get()).data()!;
      expect(vote['uid'], 'me');
      expect(vote['matchupId'], 'sample-1');
      expect(vote['card'], 1);
      expect(vote['type'], 'win');
      expect(vote['promptDateId'], 'sample-day');
      expect((await firestore.collection('Dislikes').get()).docs, isEmpty);
    });

    test('a downvote adds an anonymous dislike and the post count', () async {
      final m = sampleMatchups().first;
      await firestore.doc('Posts/s1b').set({
        'counts': {'dislikes': 2}
      });

      await castVote(
          firestore, 'me', m, const MatchupVote(1, VoteType.downvote));

      final vote = (await firestore.doc('Votes/sample-1_me').get()).data()!;
      expect(vote['type'], 'dislike');
      final dislike =
          (await firestore.doc('Dislikes/s1b_me').get()).data()!;
      expect(dislike['targetId'], 's1b');
      expect(dislike['targetType'], 'post');
      expect(dislike['matchupId'], 'sample-1');
      final post = (await firestore.doc('Posts/s1b').get()).data()!;
      expect(post['counts']['dislikes'], 3);
    });
  });

  test('parseSegment falls back to global', () {
    expect(parseSegment('Friends'), Segment.friends);
    expect(parseSegment('local'), Segment.local);
    expect(parseSegment(null), Segment.global);
    expect(parseSegment('mars'), Segment.global);
  });
}
