import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/friend_prompts.dart';
import '../data/prompt_stats.dart';
import '../data/prompt_day.dart';
import '../data/prompts.dart';
import '../data/sample_prompts.dart';
import '../database/models.dart';

/// The Create tab: which prompt is showing, the user's answer or unsent draft
/// for each one, and each prompt's stats. Live daily prompts come from
/// PromptService; today's friend prompts (from FriendPrompts) follow them,
/// then sample prompts in debug builds. Drafts and sample answers survive
/// reloads, so leaving the tab keeps them.
class CreateService with ChangeNotifier {
  List<DbPrompt> _prompts = List.empty(growable: true);
  List<DbPost?> _posts = List.empty(growable: true);
  int _page = 0;
  int _streak = 0;
  final Map<String, String> _drafts = {};
  final Map<String, PromptStats> _stats = {};

  /// the user's friends, uid to username, for "friends who answered"
  Map<String, String> _friends = const {};

  /// likes the user changed on this phone, overriding PromptStats.likedByMe
  final Map<String, bool> _liked = {};
  Map<String, DbPost>? _samplePosts;

  /// today's friend prompts (the user's own included), with the user's
  /// answers to them by promptId
  List<DbPrompt> _friendPrompts = List.empty(growable: true);
  final Map<String, DbPost> _friendPosts = {};
  final Map<String, PromptCreator> _creators = {};

  /// prompt day of the user's last friend prompt, for the one-a-day limit
  String? _lastCreatedDayId;

  /// sample prompts are showing, so the streak is sample data too
  bool _usingSamples = false;
  bool get usingSamples => _usingSamples;

  List<DbPrompt> get prompts => _prompts;
  int get page => _page;
  int get length => _prompts.length;
  int get streak => _streak;

  DbPrompt? get current => _page < _prompts.length ? _prompts[_page] : null;

  /// The user's answer to prompt i, or null
  DbPost? postFor(int i) => i < _posts.length ? _posts[i] : null;
  bool answered(int i) => postFor(i) != null;
  int get answeredCount => _posts.where((p) => p != null).length;

  /// Prompts the user can answer, leaving out the awaiting placeholder
  int get answerableCount => _prompts.where((p) => !isAwaitingPrompt(p)).length;

  String draftFor(int i) => _drafts[_key(_prompts[i])] ?? '';
  PromptStats? statsFor(int i) => _stats[_key(_prompts[i])];

  bool likedFor(int i) =>
      _liked[_key(_prompts[i])] ?? statsFor(i)?.likedByMe ?? false;

  /// The prompt's like count, counting the user's like as it is now
  int likesFor(int i) {
    final s = statsFor(i);
    if (s == null) return 0;
    return s.likes - (s.likedByMe ? 1 : 0) + (likedFor(i) ? 1 : 0);
  }

  /// Flips the user's like on prompt i and returns the new state
  bool toggleLike(int i) {
    final liked = !likedFor(i);
    _liked[_key(_prompts[i])] = liked;
    notifyListeners();
    return liked;
  }

  /// Forgets the phone's change to prompt i's like, so its stats decide
  void clearLike(int i) {
    _liked.remove(_key(_prompts[i]));
    notifyListeners();
  }

  String _key(DbPrompt p) => '${p.promptDateId}/${p.promptId}';

  /// Who made prompt i. Live daily prompts come from the Chuckler account.
  PromptCreator creatorFor(int i) {
    final p = _prompts[i];
    if (_creators[_key(p)] != null) return _creators[_key(p)]!;
    if (isSamplePrompt(p)) return sampleCreator(p);
    if (p.creatorUid == null || p.creatorUid == chucklerUid) return chuckler;
    return PromptCreator(
        uid: p.creatorUid!,
        username: p.creatorUsername ?? '',
        photoUrl: p.creatorPhotoUrl ?? '');
  }

  /// One new friend prompt per prompt day
  bool canCreatePrompt(DateTime nowUtc) =>
      _lastCreatedDayId != promptDayId(nowUtc);

  /// Adds a friend prompt the user just made, shows it, and returns its page
  int addCreatedPrompt(DbPrompt prompt, PromptCreator creator, DateTime nowUtc) {
    _creators[_key(prompt)] = creator;
    _lastCreatedDayId = promptDayId(nowUtc);
    if (!_friendPrompts.any((p) => _key(p) == _key(prompt))) {
      _friendPrompts.add(prompt);
    }
    // where a reload would put it: after the daily prompts, before samples
    _rebuild();
    _page = _prompts.indexWhere((p) => _key(p) == _key(prompt));
    notifyListeners();
    return _page;
  }

  /// Sets today's friend prompts and the user's answers to them (promptId
  /// to post). Their own prompt today uses up the one-a-day limit.
  void setFriendPrompts(List<DbPrompt> prompts, Map<String, DbPost> myAnswers,
      {required String uid, required DateTime nowUtc}) {
    final today = promptDayId(nowUtc);
    _friendPrompts = [...prompts];
    _friendPosts
      ..clear()
      ..addAll(myAnswers);
    if (prompts.any((p) => p.creatorUid == uid && p.promptDateId == today)) {
      _lastCreatedDayId = today;
    }
    final current = _page < _prompts.length ? _key(_prompts[_page]) : null;
    _rebuild();
    final keep = _prompts.indexWhere((p) => _key(p) == current);
    _page = keep >= 0 ? keep : 0;
    notifyListeners();
  }

  List<DbPrompt> _live = const [];
  List<DbPost?> _livePosts = const [];
  bool _includeSamples = false;

  /// Shows the live prompts, then today's friend prompts, then the sample
  /// prompts when includeSamples is set. livePosts[i] is the user's answer
  /// to live[i].
  void setPrompts(List<DbPrompt> live, List<DbPost?> livePosts,
      {bool includeSamples = false, String uid = '', String username = ''}) {
    _usingSamples = includeSamples;
    _live = [...live];
    _livePosts = [...livePosts];
    _includeSamples = includeSamples;
    if (includeSamples) {
      _samplePosts ??= sampleAnsweredPosts(uid, username);
    }
    _rebuild();
    if (_page >= _prompts.length) {
      _page = 0;
    }
    notifyListeners();
  }

  void _rebuild() {
    _prompts = [..._live];
    _posts = [
      for (int i = 0; i < _live.length; i++)
        i < _livePosts.length ? _livePosts[i] : null
    ];
    for (DbPrompt p in _friendPrompts) {
      _prompts.add(p);
      _posts.add(_friendPosts[p.promptId]);
    }
    if (_includeSamples) {
      for (DbPrompt p in samplePrompts()) {
        _prompts.add(p);
        _posts.add(_samplePosts![p.promptId]);
      }
    }
  }

  void setPage(int i) {
    if (i == _page || i < 0 || i >= _prompts.length) return;
    _page = i;
    notifyListeners();
  }

  void setDraft(int i, String text) {
    _drafts[_key(_prompts[i])] = text;
    notifyListeners();
  }

  /// Records the user's answer to prompt i and clears its draft
  void markPosted(int i, DbPost post) {
    _posts[i] = post;
    _drafts.remove(_key(_prompts[i]));
    if (isSamplePrompt(_prompts[i])) {
      _samplePosts![_prompts[i].promptId!] = post;
    } else if (isFriendPrompt(_prompts[i])) {
      _friendPosts[_prompts[i].promptId!] = post;
    }
    notifyListeners();
  }

  /// Sets whose answers count as friends' (uid to username). Takes effect at
  /// the next loadStats.
  void setFriends(Map<String, String> friends) {
    _friends = Map.unmodifiable(friends);
  }

  /// Fetches stats for every answerable prompt, or only for prompt [only].
  /// After the user posts to [only], pass [justAnswered]: the server counts
  /// the new answer a moment later, so until it shows up the count is the
  /// previous one plus the user's.
  Future<void> loadStats(FirebaseFirestore firestore, String uid,
      {int? only, bool justAnswered = false}) async {
    final prompts = _prompts;
    for (int i = 0; i < prompts.length; i++) {
      if ((only != null && i != only) || isAwaitingPrompt(prompts[i])) {
        continue;
      }
      final key = _key(prompts[i]);
      final before = _stats[key]?.answers;
      try {
        var stats = await getPromptStats(
            firestore, uid, prompts[i], postFor(i),
            friends: _friends);
        if (justAnswered && before != null && stats.answers <= before) {
          stats = stats.withAnswers(before + 1);
        }
        _stats[key] = stats;
      } catch (e) {
        // keep what was there; one bad prompt shouldn't blank the others
        debugPrint('stats for ${prompts[i].promptId}: $e');
      }
    }
    if (only == null) {
      try {
        _streak = _usingSamples
            ? sampleStreak
            : await getAnswerStreak(firestore, uid);
      } catch (e) {
        debugPrint('streak: $e');
      }
    }
    notifyListeners();
  }

  void logout() {
    _prompts = List.empty(growable: true);
    _posts = List.empty(growable: true);
    _page = 0;
    _streak = 0;
    _drafts.clear();
    _stats.clear();
    _friends = const {};
    _liked.clear();
    _samplePosts = null;
    _friendPrompts = List.empty(growable: true);
    _friendPosts.clear();
    _creators.clear();
    _lastCreatedDayId = null;
    _live = const [];
    _livePosts = const [];
    _includeSamples = false;
    _usingSamples = false;
    notifyListeners();
  }
}
