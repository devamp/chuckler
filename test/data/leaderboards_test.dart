// The Leaderboard tab's queries: friends boards built from profiles and
// History, and the server's global snapshot, against a fake Firestore.

import 'package:chuckler/data/friends.dart';
import 'package:chuckler/data/leaderboards.dart';
import 'package:chuckler/data/prompt_day.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Wednesday 2026-11-11, 12:00 UTC: the week started Monday 2026-11-09
  final now = DateTime.utc(2026, 11, 11, 12);
  const today = '2026-11-11';
  const yesterday = '2026-11-10';
  const me = FriendCard('u1', 'ava', '');
  const friends = [FriendCard('u2', 'ben', ''), FriendCard('u3', 'cleo', '')];

  Map<String, dynamic> answer(String promptId, String text, int wins,
          int votes) =>
      {
        'postId': 'post-$promptId-$text',
        'promptDateId': yesterday,
        'promptId': promptId,
        'before': 'My ',
        'after': ' is ready.',
        'answer': text,
        'final': {'wins': wins, 'votes': votes},
      };

  Future<FakeFirebaseFirestore> seeded() async {
    final f = FakeFirebaseFirestore();
    await f.doc('Users/u1/FriendView/profile').set({
      'stats': {'answers': 10, 'wins': 4},
      'week': {'start': '2026-11-09', 'answers': 2, 'wins': 3},
      'streak': {'days': '111', 'from': '2026-11-08', 'current': 3},
    });
    await f.doc('Users/u2/FriendView/profile').set({
      'stats': {'answers': 30, 'wins': 9},
      // last week's counts: this week reads as zero
      'week': {'start': '2026-11-02', 'answers': 7, 'wins': 6},
      // ended before yesterday: no current streak
      'streak': {'days': '11111', 'from': '2026-11-01', 'current': 5},
    });
    await f.doc('Users/u3/FriendView/profile').set({
      'stats': {'answers': 10, 'wins': 1},
      'week': {'start': '2026-11-09', 'answers': 3, 'wins': 1},
    });
    await f.doc('Users/u1/History/2026-11').set({
      'answers': {
        '${yesterday}_p1': answer('p1', 'a goose', 2, 4),
        // a friend prompt: kept off the boards
        '${yesterday}_u2_$yesterday':
            answer('u2_$yesterday', 'secret', 9, 9),
      },
    });
    await f.doc('Users/u2/History/2026-11').set({
      'answers': {
        '${yesterday}_p1': answer('p1', 'two geese', 3, 4),
        '${yesterday}_p2': answer('p2', 'nobody voted', 0, 0),
        // an older day
        '2026-11-01_p1': {...answer('p1', 'old', 9, 9),
          'promptDateId': '2026-11-01'},
      },
    });
    return f;
  }

  group('weeks and places', () {
    test('weekStartId is the Monday of the prompt day', () {
      expect(weekStartId('2026-11-09'), '2026-11-09');
      expect(weekStartId('2026-11-15'), '2026-11-09');
      expect(weekStartId('2026-11-08'), '2026-11-02');
      expect(weekStartId('2027-01-01'), '2026-12-28');
      expect(addDays('2026-11-30', 1), '2026-12-01');
    });

    test('ties share a place', () {
      expect(ranks([9, 5, 5, 2]), [1, 2, 2, 4]);
      expect(ranks([]), isEmpty);
    });

    test('board ids', () {
      expect(boardId(LeaderBoard.wins, LeaderPeriod.week), 'wins-week');
      expect(boardId(LeaderBoard.posts, LeaderPeriod.all), 'posts-all');
      expect(boardId(LeaderBoard.streak, LeaderPeriod.week), 'streak');
      expect(boardId(LeaderBoard.answers, LeaderPeriod.all), 'answers');
    });
  });

  group('friends boards', () {
    test('rank you and your friends on each stat', () async {
      final boards =
          await getFriendBoards(await seeded(), me, friends, now: now);
      List<(String, int)> rows(String id) =>
          [for (final e in boards[id]!.entries) (e.username, e.value)];

      expect(rows('wins-all'), [('ben', 9), ('ava', 4), ('cleo', 1)]);
      // ben's counts are from last week
      expect(rows('wins-week'), [('ava', 3), ('cleo', 1), ('ben', 0)]);
      // ties go by name
      expect(rows('posts-all'), [('ben', 30), ('ava', 10), ('cleo', 10)]);
      expect(rows('posts-week'), [('cleo', 3), ('ava', 2), ('ben', 0)]);
      expect(rows('streak'), [('ava', 3), ('ben', 0), ('cleo', 0)]);
      expect(boards['wins-all']!.me!.username, 'ava');
      expect(boards['wins-week']!.weekStart, '2026-11-09');
    });

    test("top answers are yesterday's voted answers to daily prompts",
        () async {
      final boards =
          await getFriendBoards(await seeded(), me, friends, now: now);
      final answers = boards['answers']!.answers;
      expect([for (final a in answers) (a.username, a.answer, a.wins)],
          [('ben', 'two geese', 3), ('ava', 'a goose', 2)]);
      expect(answers[1].isMe, isTrue);
      expect(boards['answers']!.dayId, yesterday);
    });

    test('a friend with no profile yet reads as zeros', () async {
      final boards = await getFriendBoards(await seeded(), me,
          [...friends, const FriendCard('u9', 'new', '')], now: now);
      final last = boards['wins-all']!.entries.last;
      expect((last.username, last.value), ('new', 0));
    });
  });

  group('global boards', () {
    test('parse the snapshot and mark you by username', () async {
      final f = FakeFirebaseFirestore();
      await f.doc('Leaderboards/wins-week').set({
        'board': 'wins-week',
        'dayId': yesterday,
        'weekStart': '2026-11-09',
        'entries': [
          {'username': 'gus', 'photoUrl': '', 'value': 12},
          {'username': 'ava', 'photoUrl': '', 'value': 3},
        ],
      });
      await f.doc('Leaderboards/answers').set({
        'board': 'answers',
        'dayId': yesterday,
        'entries': [
          {'username': 'hal', 'photoUrl': '', 'before': 'My ',
            'after': '.', 'answer': 'a goose', 'wins': 5, 'votes': 6},
        ],
      });
      final week = await getGlobalBoard(f, 'wins-week', myUsername: 'ava');
      expect(week.entries.map((e) => (e.username, e.value, e.isMe)),
          [('gus', 12, false), ('ava', 3, true)]);
      expect(week.weekStart, '2026-11-09');

      final answers = await getGlobalBoard(f, 'answers', myUsername: 'ava');
      expect(answers.answers.single.answer, 'a goose');
      expect(answers.answers.single.wins, 5);

      final missing = await getGlobalBoard(f, 'streak');
      expect(missing.isEmpty, isTrue);
    });
  });

  test('isFriendPromptId', () {
    expect(isFriendPromptId('u2_$today', today), isTrue);
    expect(isFriendPromptId('p1', today), isFalse);
  });
}
