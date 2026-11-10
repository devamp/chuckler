import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/friends.dart';
import '../data/leaderboards.dart';

/// The Leaderboard tab: which scope, board and period are showing, and the
/// boards loaded this session. Friends boards load together; global boards
/// load one at a time as they're opened.
class LeaderboardService with ChangeNotifier {
  LeaderScope _scope = LeaderScope.friends;
  LeaderBoard _board = LeaderBoard.answers;
  LeaderPeriod _period = LeaderPeriod.week;
  Map<String, Board>? _friendBoards;
  final Map<String, Board> _global = {};
  bool _loading = false;
  bool _failed = false;

  LeaderScope get scope => _scope;
  LeaderBoard get board => _board;
  LeaderPeriod get period => _period;
  bool get loading => _loading;

  /// the last load failed (offline, or refused)
  bool get failed => _failed;
  String get currentId => boardId(_board, _period);

  /// The board showing now, or null until it's loaded
  Board? get current {
    if (_scope == LeaderScope.friends) return _friendBoards?[currentId];
    return _global[currentId];
  }

  void setScope(LeaderScope s) {
    if (s == _scope) return;
    _scope = s;
    notifyListeners();
  }

  void setBoard(LeaderBoard b) {
    if (b == _board) return;
    _board = b;
    notifyListeners();
  }

  void setPeriod(LeaderPeriod p) {
    if (p == _period) return;
    _period = p;
    notifyListeners();
  }

  /// Loads the showing board if it isn't loaded yet, or again with [force]
  /// (pull to refresh). [me] and [friends] are for the friends boards.
  Future<void> ensureLoaded(
      FirebaseFirestore firestore, FriendCard me, List<FriendCard> friends,
      {bool force = false}) async {
    if (_loading || (current != null && !force)) return;
    final scope = _scope;
    final id = currentId;
    _loading = true;
    _failed = false;
    notifyListeners();
    try {
      if (scope == LeaderScope.friends) {
        _friendBoards = await getFriendBoards(firestore, me, friends);
      } else {
        if (force) _global.clear();
        _global[id] =
            await getGlobalBoard(firestore, id, myUsername: me.username);
      }
    } catch (e) {
      debugPrint('leaderboard: $e');
      _failed = true;
    }
    _loading = false;
    notifyListeners();
  }

  /// Forgets everything, so the next user starts fresh
  void logout() {
    _scope = LeaderScope.friends;
    _board = LeaderBoard.answers;
    _period = LeaderPeriod.week;
    _friendBoards = null;
    _global.clear();
    _loading = false;
    _failed = false;
    notifyListeners();
  }
}
