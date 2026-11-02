import 'package:chuckler/data/matchups.dart';
import 'package:chuckler/data/sample_matchups.dart';
import 'package:chuckler/state/voting_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late VotingService s;
  late int notified;

  setUp(() {
    s = VotingService();
    notified = 0;
    s.addListener(() => notified++);
  });

  test('starts empty and not loaded', () {
    expect(s.loaded, isFalse);
    expect(s.current, isNull);
    expect(s.canGoBack, isFalse);
  });

  test('setMatchups leaves out matchups with the user\'s own answer', () {
    s.setMatchups(sampleMatchups(), 'sample-u3');

    expect(s.loaded, isTrue);
    expect(s.length, 4);
    expect(s.current!.id, 'sample-1');
    expect(notified, 1);
    // sample-2 has sample-u3's answer
    expect(List.generate(s.length, (i) {
      final id = s.current!.id;
      s.next();
      return id;
    }), ['sample-1', 'sample-3', 'sample-4', 'sample-5']);
  });

  test('a win adds to that answer and is final', () {
    s.setMatchups(sampleMatchups(), 'me');
    final m = s.current!;

    expect(s.vote(0, VoteType.win), isTrue);
    expect(m.answers[0].wins, 32);
    expect(s.voteFor(m)!.card, 0);
    expect(s.voteFor(m)!.type, VoteType.win);

    // a second action on the same matchup is refused
    expect(s.vote(1, VoteType.win), isFalse);
    expect(s.vote(1, VoteType.downvote), isFalse);
    expect(m.answers[1].wins, 19);
    expect(m.answers[1].downvotes, 4);
  });

  test('a downvote does not count as a win for the other answer', () {
    s.setMatchups(sampleMatchups(), 'me');
    final m = s.current!;

    s.vote(1, VoteType.downvote);

    expect(m.answers[1].downvotes, 5);
    expect(m.answers[0].wins, 31);
    expect(m.answers[1].wins, 19);
  });

  test('pickPercent counts only wins, and is 0 with no wins', () {
    final m = sampleMatchups().first; // 31 vs 19
    expect(m.pickPercent(0), 62);
    expect(m.pickPercent(1), 38);
    final empty = sampleMatchups()[2];
    expect(empty.pickPercent(0), 0);
    expect(empty.pickPercent(1), 0);
  });

  test('next skips forward and runs out at the end', () {
    s.setMatchups(sampleMatchups(), 'me');
    for (var i = 0; i < 5; i++) {
      s.next();
    }
    expect(s.current, isNull);
    s.next();
    expect(s.index, 5);
  });

  test('back shows a voted matchup without allowing a new vote', () {
    s.setMatchups(sampleMatchups(), 'me');
    final first = s.current!;
    s.vote(0, VoteType.win);
    s.next();

    s.back();

    expect(s.current, same(first));
    expect(s.hasVoted(first), isTrue);
    expect(s.vote(1, VoteType.win), isFalse);
  });

  test('back to a skipped matchup still allows voting', () {
    s.setMatchups(sampleMatchups(), 'me');
    final first = s.current!;
    s.next();

    s.back();

    expect(s.current, same(first));
    expect(s.vote(1, VoteType.win), isTrue);
  });

  test('back does nothing on the first matchup', () {
    s.setMatchups(sampleMatchups(), 'me');
    notified = 0;
    s.back();
    expect(s.index, 0);
    expect(notified, 0);
  });
}
