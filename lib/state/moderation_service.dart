import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/moderation.dart';

/// What the user blocked, reported and filters out, so every screen can
/// hide it: matchups on Home, comments, friend prompts and leaderboard
/// answers. Loaded after login; cleared by signOut.
class ModerationService with ChangeNotifier {
  final Future<List<WordCategory>> Function() _loadCategories;

  ModerationService({Future<List<WordCategory>> Function()? loadCategories})
      : _loadCategories = loadCategories ?? loadWordList;

  List<WordCategory> _categories = const [];
  Set<String>? _filter;
  final Map<String, BlockedUser> _blocked = {};
  final Set<String> _reportedMatchups = {};
  final Set<String> _reportedComments = {};
  final Set<String> _reportedPrompts = {};
  final Set<String> _blockedMatchups = {};
  Set<String> _filterWords = const {};
  bool _loaded = false;

  bool get loaded => _loaded;
  List<WordCategory> get categories => _categories;

  /// The categories hidden for this user (the defaults until they choose)
  Set<String> get contentFilter => _filter ?? defaultContentFilter(_categories);
  List<BlockedUser> get blocked => _blocked.values.toList()
    ..sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));

  /// Reads the word list, the content filter and what to hide (four reads)
  Future<void> load(FirebaseFirestore firestore, String uid) async {
    try {
      _categories = await _loadCategories();
    } catch (e) {
      debugPrint('word list: $e');
    }
    try {
      final results = await Future.wait([
        getModerationState(firestore, uid),
        getContentFilter(firestore, uid),
      ]);
      final state = results[0] as ModerationState;
      _filter = results[1] as Set<String>?;
      _blocked
        ..clear()
        ..addEntries(state.blocked.map((b) => MapEntry(b.uid, b)));
      _reportedMatchups
        ..clear()
        ..addAll(state.reportedMatchups);
      _reportedComments
        ..clear()
        ..addAll(state.reportedComments);
      _reportedPrompts
        ..clear()
        ..addAll(state.reportedPrompts);
      _blockedMatchups
        ..clear()
        ..addAll(state.blockedMatchups);
    } catch (e) {
      debugPrint('moderation: $e');
    }
    _refreshWords();
    _loaded = true;
    notifyListeners();
  }

  void _refreshWords() {
    final on = contentFilter;
    _filterWords = wordsIn(_categories.where((c) => on.contains(c.id)));
  }

  // ---- checks ---------------------------------------------------------

  /// Whether a username is allowed (no listed word from any category)
  bool allowsUsername(String name) =>
      !containsBlockedWords(name, wordsIn(_categories));

  /// Whether text has a word from a category this user filters out
  bool filters(String text) => containsBlockedWords(text, _filterWords);

  bool isBlocked(String uid) => _blocked.containsKey(uid);
  bool isBlockedUsername(String username) {
    final name = username.toLowerCase();
    return _blocked.values.any((b) => b.username.toLowerCase() == name);
  }

  /// Whether to keep a matchup out of the queue: reported, a blocked
  /// user's (from the server's list), or text the user filters out
  bool hidesMatchup(
          {required String id,
          required String prompt,
          required Iterable<String> answers}) =>
      _reportedMatchups.contains(id) ||
      _blockedMatchups.contains(id) ||
      filters(prompt) ||
      answers.any(filters);

  bool hidesComment(
          {required String id,
          required String uid,
          required String username,
          required String text}) =>
      _reportedComments.contains(id) ||
      isBlocked(uid) ||
      isBlockedUsername(username) ||
      filters(text);

  bool hidesPrompt(
          {required String id, String? creatorUid, required String text}) =>
      _reportedPrompts.contains(id) ||
      (creatorUid != null && isBlocked(creatorUid)) ||
      filters(text);

  // ---- actions --------------------------------------------------------

  /// Reports something and hides it for this user straight away
  Future<void> report(
    FirebaseFirestore firestore, {
    required String reporter,
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? postId,
    String? matchupId,
  }) async {
    await reportContent(firestore,
        reporter: reporter,
        target: target,
        targetId: targetId,
        reason: reason,
        postId: postId,
        matchupId: matchupId);
    switch (target) {
      case ReportTarget.answer:
        if (matchupId != null) _reportedMatchups.add(matchupId);
      case ReportTarget.comment:
        _reportedComments.add(targetId);
      case ReportTarget.prompt:
        _reportedPrompts.add(targetId);
      case ReportTarget.user:
        break;
    }
    notifyListeners();
  }

  /// Blocks someone; [matchupId] (the one on screen) leaves the queue now,
  /// their others once the server has listed them
  Future<void> block(FirebaseFirestore firestore, String me, BlockedUser them,
      {String? matchupId}) async {
    await blockUser(firestore, me, them);
    _blocked[them.uid] = them;
    if (matchupId != null) _blockedMatchups.add(matchupId);
    notifyListeners();
  }

  Future<void> unblock(
      FirebaseFirestore firestore, String me, String uid) async {
    await unblockUser(firestore, me, uid);
    _blocked.remove(uid);
    notifyListeners();
  }

  /// Turns a category of the content filter on or off, and saves it
  Future<void> setFiltered(
      FirebaseFirestore firestore, String uid, String category, bool on) async {
    final next = {...contentFilter};
    on ? next.add(category) : next.remove(category);
    _filter = next;
    _refreshWords();
    notifyListeners();
    await saveContentFilter(firestore, uid, next);
  }

  /// Forgets everything, for the next user
  void logout() {
    _filter = null;
    _blocked.clear();
    _reportedMatchups.clear();
    _reportedComments.clear();
    _reportedPrompts.clear();
    _blockedMatchups.clear();
    _refreshWords();
    _loaded = false;
    notifyListeners();
  }
}
