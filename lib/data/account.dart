import 'package:cloud_firestore/cloud_firestore.dart';
import 'awards.dart';
import 'prompt_stats.dart' show StreakRecord;

// The Account tab's reads: the user's profile (stats, streak, awards; kept
// by Cloud Functions), their answers from History, and their notifications.
// See docs/data-model.md.

DocumentReference<Map<String, dynamic>> _profileRef(
        FirebaseFirestore firestore, String uid) =>
    firestore
        .collection('Users')
        .doc(uid)
        .collection('FriendView')
        .doc('profile');

/// Users/{uid}/FriendView/profile
class AccountProfile {
  /// the raw doc, for award stats (see profileStat)
  final Map<String, dynamic> data;

  const AccountProfile(this.data);

  static const empty = AccountProfile({});

  int stat(String name) => profileStat(data, name);
  int get answers => stat('answers');
  int get wins => stat('wins');
  int get comments => stat('comments');
  int get friends => stat('friends');
  StreakRecord get streak =>
      StreakRecord.fromMap(data['streak'] as Map<String, dynamic>?);
}

/// One read
Future<AccountProfile> getProfile(
    FirebaseFirestore firestore, String uid) async {
  final doc = await _profileRef(firestore, uid).get();
  return AccountProfile(doc.data() ?? const {});
}

/// How an answer did: its final stats once its prompt day is finished, or
/// its post's live counts before that
class AnswerResult {
  final int wins;
  final int votes;
  final int dislikes;
  final int comments;
  final int matchups;

  /// wins ÷ (wins + dislikes); null with neither
  final double? winRate;

  /// true once the day's results are in (History `final`)
  final bool isFinal;

  const AnswerResult(
      {this.wins = 0,
      this.votes = 0,
      this.dislikes = 0,
      this.comments = 0,
      this.matchups = 0,
      this.winRate,
      this.isFinal = false});

  factory AnswerResult.fromMap(Map<String, dynamic>? m,
      {required bool isFinal}) {
    int n(String k) => (m?[k] as num?)?.toInt() ?? 0;
    final wins = n('wins');
    final dislikes = n('dislikes');
    return AnswerResult(
      wins: wins,
      votes: n('votes'),
      dislikes: dislikes,
      comments: n('comments'),
      matchups: n('matchups'),
      winRate: (m?['winRate'] as num?)?.toDouble() ??
          (wins + dislikes > 0 ? wins / (wins + dislikes) : null),
      isFinal: isFinal,
    );
  }
}

/// One of the user's answers, from History/{yyyy-MM}
class AnswerEntry {
  final String postId;
  final String promptDateId;
  final String promptId;
  final String before;
  final String after;
  final String answer;
  final DateTime? at;
  final AnswerResult result;

  const AnswerEntry(this.postId, this.promptDateId, this.promptId, this.before,
      this.after, this.answer, this.at, this.result);

  factory AnswerEntry.fromMap(Map<String, dynamic> m) {
    final fin = m['final'] as Map<String, dynamic>?;
    return AnswerEntry(
      m['postId'] as String? ?? '',
      m['promptDateId'] as String? ?? '',
      m['promptId'] as String? ?? '',
      m['before'] as String? ?? '',
      m['after'] as String? ?? '',
      m['answer'] as String? ?? '',
      (m['at'] as Timestamp?)?.toDate(),
      AnswerResult.fromMap(fin, isFinal: fin != null),
    );
  }

  AnswerEntry withResult(AnswerResult r) =>
      AnswerEntry(postId, promptDateId, promptId, before, after, answer, at, r);

  /// newest first: by day, then by when it was posted
  static int newestFirst(AnswerEntry a, AnswerEntry b) {
    final byDay = b.promptDateId.compareTo(a.promptDateId);
    if (byDay != 0) return byDay;
    final at = (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0));
    return at != 0 ? at : b.promptId.compareTo(a.promptId);
  }
}

/// A page of answers: whole History months, newest first
class AnswerPage {
  final List<AnswerEntry> answers;

  /// the month to continue from, or null when there are no more
  final String? nextBefore;

  const AnswerPage(this.answers, this.nextBefore);
}

/// The month before a yyyy-MM month id
String monthBefore(String month) {
  final y = int.parse(month.substring(0, 4));
  final m = int.parse(month.substring(5, 7));
  return m == 1 ? '${y - 1}-12' : '$y-${(m - 1).toString().padLeft(2, '0')}';
}

/// The user's answers, newest first, [months] History docs at a time (one
/// read each, by id: Firestore can't scan document ids in descending
/// order). Starts at month [from] (yyyy-MM) and goes back no further than
/// [firstMonth], the month of their first answer (the streak's `from`);
/// with no [firstMonth] it reads only [months] months. Answers whose day
/// isn't finished yet read their post's live counts (one read each, a few
/// at most).
Future<AnswerPage> getAnswerHistory(FirebaseFirestore firestore, String uid,
    {required String from, String? firstMonth, int months = 2}) async {
  final ids = <String>[];
  for (var m = from;
      ids.length < months &&
          (firstMonth == null || m.compareTo(firstMonth) >= 0);
      m = monthBefore(m)) {
    ids.add(m);
  }
  final history = firestore.collection('Users').doc(uid).collection('History');
  final docs = await Future.wait([for (final id in ids) history.doc(id).get()]);
  final next = ids.isEmpty ? null : monthBefore(ids.last);
  final hasMore =
      firstMonth != null && next != null && next.compareTo(firstMonth) >= 0;

  final answers = <AnswerEntry>[];
  for (final doc in docs) {
    final map = doc.data()?['answers'] as Map<String, dynamic>? ?? const {};
    for (final e in map.values) {
      if (e is! Map) continue;
      final entry = AnswerEntry.fromMap(Map<String, dynamic>.from(e));
      if (entry.answer.isEmpty && entry.postId.isEmpty) continue;
      answers.add(entry);
    }
  }

  // live counts for answers still in play
  await Future.wait([
    for (int i = 0; i < answers.length; i++)
      if (!answers[i].result.isFinal && answers[i].postId.isNotEmpty)
        firestore.collection('Posts').doc(answers[i].postId).get().then((post) {
          final counts = post.data()?['counts'] as Map<String, dynamic>?;
          if (counts != null) {
            answers[i] = answers[i]
                .withResult(AnswerResult.fromMap(counts, isFinal: false));
          }
        }).catchError((_) {}),
  ]);

  answers.sort(AnswerEntry.newestFirst);
  return AnswerPage(answers, hasMore ? next : null);
}

/// Users/{uid}/Notifications/{id}, written by Cloud Functions
class AppNotification {
  final String id;

  /// friendRequest, friendAdded, award, comment, results
  final String type;
  final String text;
  final DateTime? at;
  final bool seen;

  /// who it's about, for friend and comment notifications
  final String? fromUsername;
  final String? fromPhotoUrl;

  const AppNotification(this.id, this.type, this.text, this.at, this.seen,
      {this.fromUsername, this.fromPhotoUrl});

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final from = d['from'] as Map<String, dynamic>?;
    final username = from?['username'] as String?;
    return AppNotification(
      doc.id,
      d['type'] as String? ?? '',
      d['text'] as String? ?? '',
      (d['at'] as Timestamp?)?.toDate(),
      d['seen'] == true,
      fromUsername: username == null || username.isEmpty ? null : username,
      fromPhotoUrl: from?['photoUrl'] as String?,
    );
  }

  AppNotification markedSeen() => AppNotification(id, type, text, at, true,
      fromUsername: fromUsername, fromPhotoUrl: fromPhotoUrl);
}

CollectionReference<Map<String, dynamic>> _notifications(
        FirebaseFirestore firestore, String uid) =>
    firestore.collection('Users').doc(uid).collection('Notifications');

/// The latest [limit] notifications, newest first
Future<List<AppNotification>> getNotifications(
    FirebaseFirestore firestore, String uid,
    {int limit = 50}) async {
  final snap = await _notifications(firestore, uid)
      .orderBy('at', descending: true)
      .limit(limit)
      .get();
  return snap.docs.map(AppNotification.fromDoc).toList();
}

/// Marks notifications seen, in one batch (the rules allow only `seen`)
Future<void> markNotificationsSeen(
    FirebaseFirestore firestore, String uid, Iterable<String> ids) async {
  if (ids.isEmpty) return;
  final batch = firestore.batch();
  for (final id in ids) {
    batch.update(_notifications(firestore, uid).doc(id), {'seen': true});
  }
  await batch.commit();
}
