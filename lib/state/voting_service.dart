import 'package:flutter/material.dart';
import '../data/matchups.dart';

/// The swipe-voting queue on the Home tab: which matchup is showing, the
/// user's votes, and the history the back button walks through
class VotingService with ChangeNotifier {
  /// every matchup loaded; _queue is the ones the filter shows
  List<Matchup> _all = List.empty(growable: true);
  List<Matchup> _queue = List.empty(growable: true);
  MatchupFilter _filter = MatchupFilter.all;
  int _index = 0;
  final Map<String, MatchupVote> _votes = {};
  final Map<String, List<MatchupAuthor>> _authors = {};
  bool _loaded = false;

  /// prompts the user hid from the queue (today's only)
  Set<String> _hidden = {};

  bool get loaded => _loaded;
  MatchupFilter get filter => _filter;

  /// how many loaded matchups a filter would show
  int countFor(MatchupFilter f) => _all.where((m) => _shows(f, m)).length;

  Set<String> get hiddenPrompts => Set.unmodifiable(_hidden);

  bool _shows(MatchupFilter f, Matchup m) =>
      f.shows(m) && !_hidden.contains(m.promptId);
  int get index => _index;
  int get length => _queue.length;

  /// null once the user has gone through every matchup
  Matchup? get current => _index < _queue.length ? _queue[_index] : null;
  bool get canGoBack => _index > 0;
  bool get canGoNext => _index < _queue.length;

  /// The matchup [delta] places from the current one, for drawing the
  /// neighbours while swiping. null past either end (past the last one is
  /// the caught-up page).
  Matchup? peek(int delta) {
    final i = _index + delta;
    return i >= 0 && i < _queue.length ? _queue[i] : null;
  }

  MatchupVote? voteFor(Matchup m) => _votes[m.id];

  /// Who wrote each answer, known once the user has voted (card order)
  List<MatchupAuthor>? authorsFor(Matchup m) => _authors[m.id];

  void setAuthors(Matchup m, List<MatchupAuthor> authors){
    _authors[m.id] = authors;
    notifyListeners();
  }
  bool hasVoted(Matchup m) => _votes.containsKey(m.id);

  /// Replaces the queue, leaving out matchups that include one of the
  /// user's own answers (myPostIds)
  /// [hidden] is the prompts the user hid today.
  void setMatchups(List<Matchup> matchups, Set<String> myPostIds,
      {Set<String> hidden = const {}}){
    _all = matchups.where((m) => !m.includesAnyPost(myPostIds)).toList();
    _hidden = {...hidden};
    _queue = _all.where((m) => _shows(_filter, m)).toList();
    _index = 0;
    _votes.clear();
    _loaded = true;
    notifyListeners();
  }

  /// Shows only the matchups [f] lets through, from the first one not
  /// voted on yet. Votes stay final across filters.
  void setFilter(MatchupFilter f){
    if (f == _filter) return;
    _filter = f;
    _queue = _all.where((m) => _shows(f, m)).toList();
    final firstOpen = _queue.indexWhere((m) => !hasVoted(m));
    _index = firstOpen < 0 ? _queue.length : firstOpen;
    notifyListeners();
  }

  /// Takes every matchup for [promptId] out of the queue. The user stays
  /// where they were: if the current matchup was for that prompt, the next
  /// one slides into its place.
  void hidePrompt(String promptId){
    if (!_hidden.add(promptId)) return;
    _requeue();
  }

  /// Puts a hidden prompt's matchups back (Undo), returning to [current]
  /// if it's in the queue again
  void unhidePrompt(String promptId, {Matchup? current}){
    if (!_hidden.remove(promptId)) return;
    _requeue(returnTo: current);
  }

  /// Rebuilds the queue after the hidden prompts change, keeping the place:
  /// [returnTo] if given and shown, else the same matchup (or the one that
  /// now follows the spot it held)
  void _requeue({Matchup? returnTo}){
    final before = _queue.take(_index).toSet();
    final was = current;
    _queue = _all.where((m) => _shows(_filter, m)).toList();
    final target = returnTo ?? was;
    final at = target == null ? -1 : _queue.indexOf(target);
    _index = at >= 0 ? at : _queue.where(before.contains).length;
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
    _all = List.empty(growable: true);
    _queue = List.empty(growable: true);
    _filter = MatchupFilter.all;
    _hidden = {};
    _index = 0;
    _votes.clear();
    _authors.clear();
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
