// Tests for the Create tab's stats helpers and sample data.

import 'package:chuckler/data/friend_prompts.dart';
import 'package:chuckler/data/matchups.dart';
import 'package:chuckler/data/prompt_stats.dart';
import 'package:chuckler/data/sample_prompts.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/createpage/create_prompt_card.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

DbPrompt located(String? location) =>
    DbPrompt('', '', 'd', 'p', null, 'prompt')..location = location;

void main() {
  test('segmentOf reads the prompt location, defaulting to global', () {
    expect(segmentOf(located('friends')), Segment.friends);
    expect(segmentOf(located('Local')), Segment.local);
    expect(segmentOf(located('global')), Segment.global);
    expect(segmentOf(located('nearby')), Segment.global);
    expect(segmentOf(located(null)), Segment.global);
  });

  test('compactCount shortens large numbers', () {
    expect(compactCount(999), '999');
    expect(compactCount(1000), '1k');
    expect(compactCount(1250), '1.3k');
    expect(compactCount(10000), '10k');
    expect(compactCount(152000), '152k');
    expect(compactCount(2000000), '2M');
  });

  test('winRate and topPercent', () {
    const s = AnswerStats(votes: 36, wins: 23, rank: 12);
    expect(s.winRate, 64);
    expect(s.topPercent(340), 4);
    expect(const AnswerStats().winRate, 0);
    expect(const AnswerStats().topPercent(340), 0);
    expect(const AnswerStats(rank: 1).topPercent(100000), 1);
  });

  test('timeLeftLabel counts down to the 05:00 UTC rollover', () {
    expect(timeLeftLabel(DateTime.utc(2026, 11, 2, 23, 48)), '5h 12m left');
    expect(timeLeftLabel(DateTime.utc(2026, 11, 3, 4, 30)), '30m left');
    expect(timeLeftLabel(DateTime.utc(2026, 11, 3, 4, 59, 50)), '1m left');
    expect(timeLeftLabel(DateTime.utc(2026, 11, 3, 5)), '24h 0m left');
  });

  group('StreakRecord', () {
    const record =
        StreakRecord(days: '1101111', from: '2026-11-01', longest: 4);

    test('decodes the answered days', () {
      expect(record.answeredDays, {
        DateTime.utc(2026, 11, 1),
        DateTime.utc(2026, 11, 2),
        DateTime.utc(2026, 11, 4),
        DateTime.utc(2026, 11, 5),
        DateTime.utc(2026, 11, 6),
        DateTime.utc(2026, 11, 7),
      });
    });

    test('current streak counts trailing days, ending today or yesterday',
        () {
      expect(record.currentAsOf('2026-11-07'), 4);
      expect(record.currentAsOf('2026-11-08'), 4); // today not answered yet
      expect(record.currentAsOf('2026-11-09'), 0); // a day was missed
      expect(const StreakRecord().currentAsOf('2026-11-08'), 0);
    });

    test('reads from a FriendView map, tolerating missing fields', () {
      final r = StreakRecord.fromMap(
          {'days': '11', 'from': '2026-11-07', 'current': 2, 'longest': 2});
      expect(r.currentAsOf('2026-11-08'), 2);
      expect(StreakRecord.fromMap(null).answeredDays, isEmpty);
    });
  });

  test('sample stats depend on whether and when you answered', () {
    final prompts = samplePrompts();
    final iceCream = prompts.firstWhere((p) => p.promptId == 'sample-ice-cream');
    final seeded = sampleAnsweredPosts('me', 'caden')['sample-ice-cream'];

    expect(samplePromptStats(iceCream, null).mine, isNull);
    expect(samplePromptStats(iceCream, seeded).mine!.rank, 12);

    final fresh = DbPost('sample-x', 'new', 'caden', 'me', 0, 0, 0,
        'sample-ice-cream', samplePromptDayId);
    expect(samplePromptStats(iceCream, fresh).mine!.matchups, 0);
    expect(samplePromptStats(iceCream, null).answers, 340);
  });

  test('sample streak history ends in a streak of sampleStreak days', () {
    final now = DateTime.utc(2026, 11, 2, 15);
    final h = sampleStreakHistory(now, 'caden');
    for (var d = 0; d < sampleStreak; d++) {
      expect(h.answeredOn(now.subtract(Duration(days: d))), isTrue);
    }
    expect(h.answeredOn(now.subtract(const Duration(days: sampleStreak))),
        isFalse);
    expect(h.myPlace, 4);
    expect(h.standings[h.myPlace - 1].username, 'caden');
    expect(const StreakHistory().myPlace, 0);
  });

  test('normalizePromptParts spaces the blank but keeps punctuation close',
      () {
    expect(normalizePromptParts('  My dog thinks ', ' is a snack '),
        ('My dog thinks ', ' is a snack'));
    expect(normalizePromptParts('I love', '!'), ('I love ', '!'));
    expect(normalizePromptParts('', 'is my spirit animal'),
        ('', ' is my spirit animal'));
    expect(normalizePromptParts('Say "', '"'), ('Say " ', '"'));
  });

  group('live prompt stats', () {
    late FakeFirebaseFirestore firestore;
    final prompt = DbPrompt('a', '', '2026-11-08', 'p1', '2026-11-08', null);

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      await promptRef(firestore, prompt).set({
        'counts': {'answers': 12, 'likes': 1},
        'likedBy': ['someone'],
      });
    });

    test('reads answers and likes from the prompt doc', () async {
      final stats = await getPromptStats(firestore, 'me', prompt, null);
      expect(stats.answers, 12);
      expect(stats.likes, 1);
      expect(stats.likedByMe, isFalse);
      expect(stats.mine, isNull);
    });

    test('likePrompt adds and removes the uid with the count', () async {
      await likePrompt(firestore, 'me', prompt, true);
      var stats = await getPromptStats(firestore, 'me', prompt, null);
      expect(stats.likes, 2);
      expect(stats.likedByMe, isTrue);

      await likePrompt(firestore, 'me', prompt, false);
      stats = await getPromptStats(firestore, 'me', prompt, null);
      expect(stats.likes, 1);
      expect(stats.likedByMe, isFalse);
    });

    test('your answer\'s stats come from its post', () async {
      await firestore.collection('Posts').doc('post1').set({
        'counts': {'matchups': 3, 'votes': 5, 'wins': 4, 'dislikes': 1},
        'rank': 2,
      });
      final mine = DbPost('post1', 'x', 'caden', 'me', 0, 0, 0, 'p1',
          '2026-11-08');

      final stats = (await getPromptStats(firestore, 'me', prompt, mine)).mine!;

      expect([stats.matchups, stats.votes, stats.wins, stats.downvotes],
          [3, 5, 4, 1]);
      expect(stats.rank, 2);
    });

    test('the streak is read from FriendView/profile', () async {
      await firestore
          .collection('Users')
          .doc('me')
          .collection('FriendView')
          .doc('profile')
          .set({
        'streak': {'days': '1011', 'from': '2026-11-05', 'longest': 2}
      });

      final record = await getStreakRecord(firestore, 'me');

      expect(record.currentAsOf('2026-11-08'), 2);
      expect(record.answeredDays, hasLength(3));
    });
  });

  group('getFriendsWhoAnswered', () {
    final prompt = DbPrompt('My ', '', '2026-11-08', 'p1', '2026-11-08', null);

    test('finds friends\' answers past the 30-per-query limit', () async {
      final firestore = FakeFirebaseFirestore();
      final friends = <String, String>{};
      for (var i = 0; i < 40; i++) {
        friends['u$i'] = 'friend$i';
      }
      // friends 5 and 35 answered (different whereIn chunks), plus a stranger
      for (final uid in ['u5', 'u35', 'stranger']) {
        await firestore.collection('Posts').add({
          'uid': uid,
          'promptId': 'p1',
          'promptDateId': '2026-11-08',
        });
      }
      // an answer to another prompt doesn't count
      await firestore.collection('Posts').add(
          {'uid': 'u6', 'promptId': 'p2', 'promptDateId': '2026-11-08'});

      expect(await getFriendsWhoAnswered(firestore, prompt, friends),
          ['friend35', 'friend5']);
    });

    test('no friends means no query', () async {
      expect(
          await getFriendsWhoAnswered(FakeFirebaseFirestore(), prompt, {}),
          isEmpty);
    });
  });
}
