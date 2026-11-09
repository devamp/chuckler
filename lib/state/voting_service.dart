import 'package:flutter/material.dart';
import '../data/matchups.dart';

/// The swipe-voting queue on the Home tab: which matchup is showing, the
/// user's votes, and the history the back button walks through
class VotingService with ChangeNotifier {
  List<Matchup> _queue = List.empty(growable: true);
  int _index = 0;
  final Map<String, MatchupVote> _votes = {};
  bool _loaded = false;

  bool get loaded => _loaded;
  int get index => _index;
  int get length => _queue.length;

  /// null once the user has gone through every matchup
  Matchup? get current => _index < _queue.length ? _queue[_index] : null;
  bool get canGoBack => _index > 0;

  MatchupVote? voteFor(Matchup m) => _votes[m.id];
  bool hasVoted(Matchup m) => _votes.containsKey(m.id);

  /// Replaces the queue, leaving out matchups that include one of the
  /// user's own answers (myPostIds)
  void setMatchups(List<Matchup> matchups, Set<String> myPostIds){
    _queue = matchups.where((m) => !m.includesAnyPost(myPostIds)).toList();
    _index = 0;
    _votes.clear();
    _loaded = true;
    notifyListeners();
  }

  /// Records the user's one action on the current matchup and updates its
  /// counts locally. Returns false if they already voted, since votes are
  /// final.
  bool vote(int card, VoteType type){
    final m = current;
    if (m == null || hasVoted(m)) {
      return false;
    }
    final v = MatchupVote(card, type);
    _votes[m.id] = v;
    if (type == VoteType.win) {
      m.answers[card].wins++;
    } else {
      m.answers[card].downvotes++;
    }
    notifyListeners();
    return true;
  }

  /// Takes back a vote the server refused, undoing its local counts
  void undoVote(Matchup m){
    final v = _votes.remove(m.id);
    if (v == null) return;
    if (v.type == VoteType.win) {
      m.answers[v.card].wins--;
    } else {
      m.answers[v.card].downvotes--;
    }
    notifyListeners();
  }

  /// Forgets the queue, so the next visit to Home loads it again
  void logout(){
    _queue = List.empty(growable: true);
    _index = 0;
    _votes.clear();
    _loaded = false;
    notifyListeners();
  }

  /// Moves to the next matchup: a skip before voting, "next" after
  void next(){
    if (_index < _queue.length) {
      _index++;
      notifyListeners();
    }
  }

  /// Returns to the previous matchup. Its vote, if any, stays final; a
  /// skipped matchup can still be voted on.
  void back(){
    if (canGoBack) {
      _index--;
      notifyListeners();
    }
  }
}
