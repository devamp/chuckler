import 'package:chuckler/data/account.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> entry(String day, String promptId, String answer,
        {Map<String, dynamic>? fin, DateTime? at}) =>
    {
      'postId': 'post-$day-$promptId',
      'promptDateId': day,
      'promptId': promptId,
      'before': 'The best ',
      'after': ' ever.',
      'answer': answer,
      if (at != null) 'at': Timestamp.fromDate(at),
      if (fin != null) 'final': fin,
    };

void main() {
  late FakeFirebaseFirestore firestore;
  setUp(() => firestore = FakeFirebaseFirestore());

  group('getProfile', () {
    test('reads stats and streak', () async {
      await firestore.doc('Users/u1/FriendView/profile').set({
        'stats': {'answers': 4, 'wins': 9, 'comments': 2, 'friends': 3},
        'streak': {'days': '11', 'from': '2026-11-08', 'longest': 2},
      });
      final p = await getProfile(firestore, 'u1');
      expect([p.answers, p.wins, p.comments, p.friends], [4, 9, 2, 3]);
      expect(p.streak.longest, 2);
    });

    test('a missing profile is all zeros', () async {
      final p = await getProfile(firestore, 'nobody');
      expect([p.answers, p.wins, p.comments, p.friends], [0, 0, 0, 0]);
    });
  });

  group('getAnswerHistory', () {
    setUp(() async {
      await firestore.doc('Users/u1/History/2026-10').set({
        'answers': {
          '2026-10-30_p1': entry('2026-10-30', 'p1', 'october',
              fin: {'wins': 1, 'votes': 2, 'dislikes': 1, 'winRate': 0.5}),
        },
      });
      await firestore.doc('Users/u1/History/2026-11').set({
        'answers': {
          '2026-11-08_p1': entry('2026-11-08', 'p1', 'older',
              fin: {'wins': 3, 'votes': 4, 'comments': 1, 'winRate': 0.75}),
          '2026-11-09_p1': entry('2026-11-09', 'p1', 'first today',
              at: DateTime.utc(2026, 11, 9, 6)),
          '2026-11-09_p2': entry('2026-11-09', 'p2', 'second today',
              at: DateTime.utc(2026, 11, 9, 7)),
        },
      });
      await firestore.doc('Posts/post-2026-11-09-p1').set({
        'counts': {'wins': 2, 'votes': 5, 'comments': 1, 'dislikes': 0},
      });
    });

    test('newest first, final stats for finished days, live otherwise',
        () async {
      final page = await getAnswerHistory(firestore, 'u1',
          from: '2026-11', firstMonth: '2026-10');
      expect(page.answers.map((a) => a.answer),
          ['second today', 'first today', 'older', 'october']);
      expect(page.nextBefore, isNull); // reached the first month

      final live = page.answers[1];
      expect(live.result.isFinal, isFalse);
      expect([live.result.wins, live.result.votes, live.result.comments],
          [2, 5, 1]);
      expect(live.result.winRate, 1);
      // no post doc: zeros
      expect(page.answers[0].result.votes, 0);

      final older = page.answers[2];
      expect(older.result.isFinal, isTrue);
      expect(older.result.wins, 3);
      expect(older.result.winRate, 0.75);
      expect(older.before, 'The best ');
      expect(older.after, ' ever.');
    });

    test('pages by month back to the first answer', () async {
      final first = await getAnswerHistory(firestore, 'u1',
          from: '2026-11', firstMonth: '2026-09', months: 1);
      expect(first.answers.length, 3);
      expect(first.nextBefore, '2026-10');
      final second = await getAnswerHistory(firestore, 'u1',
          from: first.nextBefore!, firstMonth: '2026-09', months: 1);
      expect(second.answers.single.answer, 'october');
      expect(second.nextBefore, '2026-09');
      final third = await getAnswerHistory(firestore, 'u1',
          from: second.nextBefore!, firstMonth: '2026-09', months: 1);
      expect(third.answers, isEmpty); // a month with no answers
      expect(third.nextBefore, isNull);
    });

    test('without a first month, only the latest months', () async {
      final page = await getAnswerHistory(firestore, 'u1', from: '2026-11');
      expect(page.answers.length, 4);
      expect(page.nextBefore, isNull);
    });

    test('no history', () async {
      final page = await getAnswerHistory(firestore, 'u2', from: '2026-11');
      expect(page.answers, isEmpty);
      expect(page.nextBefore, isNull);
    });

    test('monthBefore', () {
      expect(monthBefore('2026-11'), '2026-10');
      expect(monthBefore('2026-01'), '2025-12');
      expect(monthBefore('2026-10'), '2026-09');
    });
  });

  group('notifications', () {
    setUp(() async {
      final n = firestore.collection('Users/u1/Notifications');
      await n.doc('a').set({
        'type': 'award',
        'text': 'You earned First Post!',
        'at': Timestamp.fromDate(DateTime.utc(2026, 11, 8)),
        'seen': true,
      });
      await n.doc('b').set({
        'type': 'comment',
        'text': 'ben commented',
        'at': Timestamp.fromDate(DateTime.utc(2026, 11, 9)),
        'seen': false,
        'from': {'username': 'ben', 'photoUrl': ''},
      });
    });

    test('newest first, with who they are from', () async {
      final list = await getNotifications(firestore, 'u1');
      expect(list.map((n) => n.id), ['b', 'a']);
      expect(list.first.fromUsername, 'ben');
      expect(list.first.seen, isFalse);
      expect(list.last.fromUsername, isNull);
      expect(list.last.type, 'award');
    });

    test('marking seen', () async {
      await markNotificationsSeen(firestore, 'u1', ['b']);
      final b = await firestore.doc('Users/u1/Notifications/b').get();
      expect(b.data()!['seen'], isTrue);
      expect(b.data()!['text'], 'ben commented');
      await markNotificationsSeen(firestore, 'u1', []); // no-op
    });
  });
}
