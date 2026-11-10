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
    s.setMatchups(sampleMatchups(), {'s2a'});

    expect(s.loaded, isTrue);
    expect(s.length, 4);
    expect(s.current!.id, 'sample-1');
    expect(notified, 1);
    // sample-2 has the user's answer s2a
    expect(List.generate(s.length, (i) {
      final id = s.current!.id;
      s.next();
      return id;
    }), ['sample-1', 'sample-3', 'sample-4', 'sample-5']);
  });

  test('a win adds to that answer and is final', () {
    s.setMatchups(sampleMatchups(), {});
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
    s.setMatchups(sampleMatchups(), {});
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
    s.setMatchups(sampleMatchups(), {});
    for (var i = 0; i < 5; i++) {
      s.next();
    }
    expect(s.current, isNull);
    s.next();
    expect(s.index, 5);
  });

  test('back shows a voted matchup without allowing a new vote', () {
    s.setMatchups(sampleMatchups(), {});
    final first = s.current!;
    s.vote(0, VoteType.win);
    s.next();

    s.back();

    expect(s.current, same(first));
    expect(s.hasVoted(first), isTrue);
    expect(s.vote(1, VoteType.win), isFalse);
  });

  test('back to a skipped matchup still allows voting', () {
    s.setMatchups(sampleMatchups(), {});
    final first = s.current!;
    s.next();

    s.back();

    expect(s.current, same(first));
    expect(s.vote(1, VoteType.win), isTrue);
  });

  test('undoVote takes back a refused vote and its counts', () {
    s.setMatchups(sampleMatchups(), {});
    final m = s.current!;
    s.vote(1, VoteType.downvote);

    s.undoVote(m);

    expect(s.hasVoted(m), isFalse);
    expect(m.answers[1].downvotes, 4);
    expect(s.vote(0, VoteType.win), isTrue);
    expect(m.answers[0].wins, 32);
  });

  test('logout forgets the queue so Home loads it again', () {
    s.setMatchups(sampleMatchups(), {});
    s.vote(0, VoteType.win);
    s.next();

    s.logout();

    expect(s.loaded, isFalse);
    expect(s.length, 0);
    expect(s.index, 0);
  });

  test('back does nothing on the first matchup', () {
    s.setMatchups(sampleMatchups(), {});
    notified = 0;
    s.back();
    expect(s.index, 0);
    expect(notified, 0);
  });

  group('filter', () {
    /// sample matchups with the last two for friend prompts
    List<Matchup> mixed() {
      final all = sampleMatchups();
      return [
        for (int i = 0; i < all.length; i++)
          i < all.length - 2
              ? all[i]
              : Matchup(
                  id: all[i].id,
                  promptId: all[i].promptId,
                  promptDateId: all[i].promptDateId,
                  promptBefore: all[i].promptBefore,
                  promptAfter: all[i].promptAfter,
                  segment: all[i].segment,
                  scope: MatchupScope.friends,
                  top: all[i].answers[0],
                  bottom: all[i].answers[1]),
      ];
    }

    test('All shows everything, Global public, Friends friend prompts', () {
      s.setMatchups(mixed(), {});
      expect(s.filter, MatchupFilter.all);
      expect(s.length, 5);
      expect(s.countFor(MatchupFilter.global), 3);
      expect(s.countFor(MatchupFilter.friends), 2);

      s.setFilter(MatchupFilter.friends);
      expect(s.length, 2);
      expect(s.current!.scope, MatchupScope.friends);

      s.setFilter(MatchupFilter.global);
      expect(s.length, 3);
      expect(s.current!.id, 'sample-1');
    });

    test('switching skips matchups already voted on; votes stay', () {
      s.setMatchups(mixed(), {});
      s.setFilter(MatchupFilter.global);
      s.vote(0, VoteType.win);
      s.setFilter(MatchupFilter.all);
      expect(s.current!.id, 'sample-2'); // sample-1 is voted
      expect(s.hasVoted(sampleMatchups().first), isTrue);
      s.setFilter(MatchupFilter.global);
      expect(s.current!.id, 'sample-2');
      expect(s.canGoBack, isTrue); // the voted one is still behind
    });

    test('the filter survives a reload and resets on logout', () {
      s.setMatchups(mixed(), {});
      s.setFilter(MatchupFilter.friends);
      s.setMatchups(mixed(), {});
      expect(s.length, 2);
      s.logout();
      expect(s.filter, MatchupFilter.all);
    });

    test('a matchup without a scope is public', () {
      final m = Matchup.fromDoc('x', {
        'answers': [
          {'postId': 'a', 'answer': 'a'},
          {'postId': 'b', 'answer': 'b'},
        ],
      })!;
      expect(m.scope, MatchupScope.public);
      final f = Matchup.fromDoc('y', {
        'scope': 'friends',
        'answers': [
          {'postId': 'a', 'answer': 'a'},
          {'postId': 'b', 'answer': 'b'},
        ],
      })!;
      expect(f.scope, MatchupScope.friends);
      expect(MatchupFilter.friends.shows(f), isTrue);
      expect(MatchupFilter.global.shows(f), isFalse);
    });
  });

  group('hidden prompts', () {
    // sample prompts in order: pilot, pilot, roommate, roommate, superpower
    List<String> queue() => [
          for (int i = 0; i < s.length; i++) s.peek(i - s.index)!.id,
        ];

    test('hiding takes every matchup for the prompt out of the queue', () {
      s.setMatchups(sampleMatchups(), {});
      s.hidePrompt('roommate');
      expect(queue(), ['sample-1', 'sample-2', 'sample-5']);
      expect(s.countFor(MatchupFilter.all), 3);
      expect(s.hiddenPrompts, {'roommate'});
    });

    test("hiding the current matchup's prompt moves on to the next one", () {
      s.setMatchups(sampleMatchups(), {});
      s.next();
      s.next(); // sample-3, roommate
      s.hidePrompt('roommate');
      expect(s.current!.id, 'sample-5');
      expect(s.index, 2);
      expect(s.canGoBack, isTrue);
    });

    test('hiding an earlier prompt keeps the current matchup', () {
      s.setMatchups(sampleMatchups(), {});
      s.next();
      s.next(); // sample-3
      s.hidePrompt('pilot');
      expect(s.current!.id, 'sample-3');
      expect(s.index, 0);
    });

    test('undo puts them back and returns to the matchup', () {
      s.setMatchups(sampleMatchups(), {});
      s.next();
      s.next();
      final m = s.current!;
      s.hidePrompt('roommate');
      s.unhidePrompt('roommate', current: m);
      expect(s.current!.id, 'sample-3');
      expect(s.length, 5);
    });

    test('hidden prompts load with the queue and stay hidden across filters',
        () {
      s.setMatchups(sampleMatchups(), {}, hidden: {'pilot'});
      expect(s.current!.id, 'sample-3');
      s.setFilter(MatchupFilter.global);
      s.setFilter(MatchupFilter.all);
      expect(queue(), ['sample-3', 'sample-4', 'sample-5']);
      s.logout();
      expect(s.hiddenPrompts, isEmpty);
    });
  });
}
