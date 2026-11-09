import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/account.dart';
import '../data/awards.dart';
import '../data/prompt_day.dart';

/// The Account tab: the user's profile (stats, streak, awards), their
/// answers and their notifications
class AccountService with ChangeNotifier {
  /// how the award catalog is loaded; tests can swap it
  final Future<List<AwardTrack>> Function() loadCatalog;

  AccountService({Future<List<AwardTrack>> Function()? loadCatalog})
      : loadCatalog = loadCatalog ?? loadAwardCatalog;

  AccountProfile _profile = AccountProfile.empty;
  List<AwardTrack> _catalog = const [];
  List<AnswerEntry> _answers = const [];
  String? _nextBefore;
  bool _moreAnswers = false;
  List<AppNotification> _notifications = const [];
  bool _loaded = false;
  bool _loadingMore = false;

  AccountProfile get profile => _profile;
  List<AnswerEntry> get answers => _answers;
  List<AppNotification> get notifications => _notifications;
  bool get loaded => _loaded;
  bool get hasMoreAnswers => _moreAnswers;
  bool get loadingMore => _loadingMore;
  int get unseenCount => _notifications.where((n) => !n.seen).length;
  List<AwardProgress> get awards => awardProgress(_catalog, _profile.data);

  /// The month of the user's first answer, from their streak
  String? get _firstMonth {
    final from = _profile.streak.from;
    return from == null || from.length < 7 ? null : historyMonthId(from);
  }

  /// Reads the profile, the latest answers and notifications. Each part
  /// that fails keeps what it had. [now] is for tests.
  Future<void> load(FirebaseFirestore firestore, String uid,
      {DateTime? now}) async {
    final thisMonth =
        historyMonthId(promptDayId((now ?? DateTime.now()).toUtc()));
    await Future.wait([
      () async {
        if (_catalog.isEmpty) _catalog = await loadCatalog();
      }()
          .catchError((e) => debugPrint('awards catalog: $e')),
      () async {
        try {
          _profile = await getProfile(firestore, uid);
        } catch (e) {
          debugPrint('profile: $e');
        }
        // the first answer's month bounds how far back History goes
        try {
          final page = await getAnswerHistory(firestore, uid,
              from: thisMonth, firstMonth: _firstMonth);
          _answers = page.answers;
          _nextBefore = page.nextBefore;
          _moreAnswers = page.nextBefore != null;
        } catch (e) {
          debugPrint('answers: $e');
        }
      }(),
      getNotifications(firestore, uid)
          .then((n) => _notifications = n)
          .catchError((e) {
        debugPrint('notifications: $e');
        return _notifications;
      }),
    ]);
    _loaded = true;
    notifyListeners();
  }

  /// The next months of answers
  Future<void> loadMoreAnswers(FirebaseFirestore firestore, String uid) async {
    if (!_moreAnswers || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await getAnswerHistory(firestore, uid,
          from: _nextBefore!, firstMonth: _firstMonth);
      _answers = [..._answers, ...page.answers];
      _nextBefore = page.nextBefore;
      _moreAnswers = page.nextBefore != null;
    } catch (e) {
      debugPrint('more answers: $e');
    }
    _loadingMore = false;
    notifyListeners();
  }

  /// Marks every loaded notification seen. The dots clear at once; the
  /// write happens behind.
  Future<void> markAllSeen(FirebaseFirestore firestore, String uid) async {
    final ids = [
      for (final n in _notifications)
        if (!n.seen) n.id
    ];
    if (ids.isEmpty) return;
    _notifications = [for (final n in _notifications) n.markedSeen()];
    notifyListeners();
    try {
      await markNotificationsSeen(firestore, uid, ids);
    } catch (e) {
      debugPrint('mark seen: $e');
    }
  }

  void logout() {
    _profile = AccountProfile.empty;
    _answers = const [];
    _nextBefore = null;
    _moreAnswers = false;
    _notifications = const [];
    _loaded = false;
    notifyListeners();
  }
}
