import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/friend_prompts.dart';
import '../data/prompt_stats.dart';
import '../data/prompts.dart';
import '../data/sample_prompts.dart';
import '../database/models.dart';

/// The Create tab: which prompt is showing, the user's answer or unsent draft
/// for each one, and each prompt's stats. Live prompts come from
/// PromptService; sample prompts and friend prompts the user made on this
/// phone follow them. Drafts and local answers survive reloads, so leaving
/// the tab keeps them.
class CreateService with ChangeNotifier {
  List<DbPrompt> _prompts = List.empty(growable: true);
  List<DbPost?> _posts = List.empty(growable: true);
  int _page = 0;
  int _streak = 0;
  final Map<String, String> _drafts = {};
  final Map<String, PromptStats> _stats = {};

  /// likes the user changed on this phone, overriding PromptStats.likedByMe
  final Map<String, bool> _liked = {};
  Map<String, DbPost>? _samplePosts;

  /// friend prompts made on this phone, with the user's answers to them
  final List<DbPrompt> _created = List.empty(growable: true);
  final Map<String, DbPost> _createdPosts = {};
  final Map<String, PromptCreator> _creators = {};

  /// UTC day of the last friend prompt made, for the one-a-day limit
  DateTime? _lastCreatedDay;

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

  /// One new friend prompt a day
  bool canCreatePrompt(DateTime nowUtc) =>
      _lastCreatedDay == null ||
      _lastCreatedDay != DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);

  /// Adds a friend prompt the user just made, shows it, and returns its page
  int addCreatedPrompt(DbPrompt prompt, PromptCreator creator, DateTime nowUtc) {
    _created.add(prompt);
    _creators[_key(prompt)] = creator;
    _lastCreatedDay = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
    _prompts.add(prompt);
    _posts.add(null);
    _page = _prompts.length - 1;
    notifyListeners();
    return _page;
  }

  /// Shows the live prompts, followed by the sample prompts when
  /// includeSamples is set. livePosts[i] is the user's answer to live[i].
  void setPrompts(List<DbPrompt> live, List<DbPost?> livePosts,
      {bool includeSamples = false, String uid = '', String username = ''}) {
    _usingSamples = includeSamples;
    _prompts = [...live];
    _posts = [
      for (int i = 0; i < live.length; i++)
        i < livePosts.length ? livePosts[i] : null
    ];
    if (includeSamples) {
      _samplePosts ??= sampleAnsweredPosts(uid, username);
      for (DbPrompt p in samplePrompts()) {
        _prompts.add(p);
        _posts.add(_samplePosts![p.promptId]);
      }
    }
    for (DbPrompt p in _created) {
      _prompts.add(p);
      _posts.add(_createdPosts[p.promptId]);
    }
    if (_page >= _prompts.length) {
      _page = 0;
    }
    notifyListeners();
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
    } else if (isLocalFriendPrompt(_prompts[i])) {
      _createdPosts[_prompts[i].promptId!] = post;
    }
    notifyListeners();
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
        var stats =
            await getPromptStats(firestore, uid, prompts[i], postFor(i));
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
    _liked.clear();
    _samplePosts = null;
    _created.clear();
    _createdPosts.clear();
    _creators.clear();
    _lastCreatedDay = null;
    _usingSamples = false;
    notifyListeners();
  }
}
