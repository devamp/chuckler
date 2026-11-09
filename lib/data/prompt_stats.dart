import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';
import 'friend_prompts.dart';
import 'matchups.dart';
import 'prompt_day.dart';
import 'sample_prompts.dart';

// Stats shown on the Create tab for each prompt. Live prompts read their
// counts from Firestore: answers (kept by the onPostCreated Cloud Function),
// likes, and the user's streak. Sample prompts use made-up numbers.
//
// TODO(cloud): the layout is in docs/data-model.md. Still to come:
//   - Prompts/{promptId}.counts.dislikes, written by the app with an
//     anonymous Dislikes doc (see likePrompt below).
//   - Posts/{postId}.counts: matchups (times paired, not views; views are
//     not counted), votes, wins, dislikes. Totalled by the checkpoint
//     function rather than on every vote, to save writes.
//   - Posts/{postId}.winsByHour: a map of hour -> wins. Feeds the bar chart.
//   - Posts/{postId}.rank: written by the checkpoint function (TODO.md
//     section 4), ranked by rate rather than raw counts.
// Clients only read these; Firestore rules deny client writes to them.

/// Which segment a prompt belongs to, from PromptDays/.../Prompts.location.
/// (The prompt's type field held its format, not its segment.) Unknown or
/// missing locations count as global.
Segment segmentOf(DbPrompt prompt) => parseSegment(prompt.location);

/// How the user's own answer to a prompt is doing
class AnswerStats {
  /// times the answer has been shown in a matchup
  final int matchups;

  /// picks cast in those matchups, for either side
  final int votes;
  final int wins;
  final int downvotes;

  /// 1 is the best answer to the prompt; 0 until the first ranking runs
  final int rank;

  /// wins in each of the last few hours, oldest first
  final List<int> winsByHour;

  const AnswerStats({
    this.matchups = 0,
    this.votes = 0,
    this.wins = 0,
    this.downvotes = 0,
    this.rank = 0,
    this.winsByHour = const [],
  });

  /// Share of the picks in its matchups that went to this answer
  int get winRate => votes == 0 ? 0 : (wins * 100 / votes).round();

  /// "Top x%" among all answers, at least 1
  int topPercent(int answers) {
    if (rank == 0 || answers == 0) return 0;
    return (rank * 100 / answers).ceil().clamp(1, 100);
  }
}

/// Stats for one prompt, plus the user's answer if they posted one
class PromptStats {
  final int answers;

  /// people who liked the prompt, including the user if likedByMe
  final int likes;
  final bool likedByMe;

  /// usernames of friends who answered
  final List<String> friendsAnswered;

  /// null until the user answers the prompt
  final AnswerStats? mine;

  const PromptStats({
    this.answers = 0,
    this.likes = 0,
    this.likedByMe = false,
    this.friendsAnswered = const [],
    this.mine,
  });

  PromptStats withAnswers(int n) => PromptStats(
      answers: n,
      likes: likes,
      likedByMe: likedByMe,
      friendsAnswered: friendsAnswered,
      mine: mine);
}

DocumentReference<Map<String, dynamic>> promptRef(
        FirebaseFirestore firestore, DbPrompt prompt) =>
    firestore
        .collection('PromptDays')
        .doc(prompt.promptDateId)
        .collection('Prompts')
        .doc(prompt.promptId);

/// Usernames of the friends who answered a prompt. [friends] maps each
/// friend's uid to their username. One query per 30 friends (Firestore's
/// whereIn limit); each answer found is one read.
Future<List<String>> getFriendsWhoAnswered(FirebaseFirestore firestore,
    DbPrompt prompt, Map<String, String> friends) async {
  if (friends.isEmpty) return const [];
  final uids = friends.keys.toList();
  final names = <String>[];
  for (var i = 0; i < uids.length; i += 30) {
    final chunk = uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30);
    final snap = await firestore
        .collection('Posts')
        .where('promptDateId', isEqualTo: prompt.promptDateId)
        .where('promptId', isEqualTo: prompt.promptId)
        .where('uid', whereIn: chunk)
        .get();
    for (final d in snap.docs) {
      final uid = d.data()['uid'] as String?;
      names.add(friends[uid] ?? d.data()['username'] as String? ?? '');
    }
  }
  return names..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}

/// Stats for one prompt. myPost is the user's answer, or null. [friends]
/// (uid to username) finds the friends who answered.
Future<PromptStats> getPromptStats(FirebaseFirestore firestore, String uid,
    DbPrompt prompt, DbPost? myPost,
    {Map<String, String> friends = const {}}) async {
  if (isLocalFriendPrompt(prompt)) {
    // only on this phone, so nobody else has answered or liked it
    return PromptStats(
      answers: myPost == null ? 0 : 1,
      mine: myPost == null ? null : const AnswerStats(),
    );
  }
  if (isSamplePrompt(prompt)) {
    return samplePromptStats(prompt, myPost);
  }
  final data = (await promptRef(firestore, prompt).get()).data() ?? {};
  final counts = data['counts'] as Map<String, dynamic>? ?? {};
  final likedBy = List<String>.from(data['likedBy'] ?? const []);
  return PromptStats(
    answers: (counts['answers'] as num?)?.toInt() ?? prompt.responses,
    likes: (counts['likes'] as num?)?.toInt() ?? 0,
    likedByMe: likedBy.contains(uid),
    friendsAnswered: await getFriendsWhoAnswered(firestore, prompt, friends),
    mine: myPost == null ? null : await getAnswerStats(firestore, myPost),
  );
}

/// How the user's answer is doing, from Posts/{postId}. Counts stay at zero
/// until voting goes live.
Future<AnswerStats> getAnswerStats(
    FirebaseFirestore firestore, DbPost post) async {
  if ((post.postId ?? '').isEmpty) return const AnswerStats();
  final data =
      (await firestore.collection('Posts').doc(post.postId).get()).data() ??
          {};
  final counts = data['counts'] as Map<String, dynamic>? ?? {};
  int count(String key) => (counts[key] as num?)?.toInt() ?? 0;
  return AnswerStats(
    matchups: count('matchups'),
    votes: count('votes'),
    wins: count('wins'),
    downvotes: count('dislikes'),
    rank: (data['rank'] as num?)?.toInt() ?? 0,
  );
}

/// Likes or unlikes a prompt for the user: one update that adds or removes
/// their uid in likedBy and moves counts.likes to match. The rules allow
/// only that change, so no Cloud Function is needed.
Future<void> likePrompt(FirebaseFirestore firestore, String uid,
    DbPrompt prompt, bool liked) async {
  // TODO(cloud): prompts can also be disliked, anonymously: create
  // Dislikes/{promptId}_{uid} and bump counts.dislikes in one batch. Remember
  // the user's likes on the phone (Isar) for a "what I liked" list; see
  // docs/data-model.md, Likes and Dislikes.
  await promptRef(firestore, prompt).update({
    'likedBy': liked
        ? FieldValue.arrayUnion([uid])
        : FieldValue.arrayRemove([uid]),
    'counts.likes': FieldValue.increment(liked ? 1 : -1),
  });
}

/// A friend's place in the streak standings
class FriendStreak {
  final String username;
  final int streak;
  final bool isMe;

  const FriendStreak(this.username, this.streak, {this.isMe = false});
}

/// The user's answered days and how their streak compares with friends'
class StreakHistory {
  /// UTC days (midnight) the user answered at least one prompt
  final Set<DateTime> answeredDays;

  /// the user and their friends, longest streak first
  final List<FriendStreak> standings;

  const StreakHistory(
      {this.answeredDays = const {}, this.standings = const []});

  bool answeredOn(DateTime day) =>
      answeredDays.contains(DateTime.utc(day.year, day.month, day.day));

  /// 1-based place among friends, 0 if the user isn't listed
  int get myPlace => standings.indexWhere((f) => f.isMe) + 1;
}

/// The streak kept on Users/{uid}/FriendView/profile by the onPostCreated
/// Cloud Function: one character per prompt day from [from], 1 = answered
class StreakRecord {
  final String days;
  final String? from;
  final int longest;

  const StreakRecord({this.days = '', this.from, this.longest = 0});

  factory StreakRecord.fromMap(Map<String, dynamic>? map) => StreakRecord(
        days: map?['days'] as String? ?? '',
        from: map?['from'] as String?,
        longest: (map?['longest'] as num?)?.toInt() ?? 0,
      );

  /// The prompt days answered, as UTC midnights
  Set<DateTime> get answeredDays {
    if (from == null) return {};
    final start = promptDayDate(from!);
    return {
      for (int i = 0; i < days.length; i++)
        if (days[i] == '1') start.add(Duration(days: i)),
    };
  }

  /// Days in a row ending today or yesterday; 0 once a day is missed. Days
  /// after the end of the string are missed days.
  int currentAsOf(String todayId) {
    if (from == null || days.isEmpty) return 0;
    final last = promptDayDate(from!).add(Duration(days: days.length - 1));
    if (promptDayDate(todayId).difference(last).inDays > 1) return 0;
    int run = 0;
    for (int i = days.length - 1; i >= 0 && days[i] == '1'; i--) {
      run++;
    }
    return run;
  }
}

Future<StreakRecord> getStreakRecord(
    FirebaseFirestore firestore, String uid) async {
  if (uid.isEmpty) return const StreakRecord();
  final doc = await firestore
      .collection('Users')
      .doc(uid)
      .collection('FriendView')
      .doc('profile')
      .get();
  return StreakRecord.fromMap(doc.data()?['streak'] as Map<String, dynamic>?);
}

/// Answered days for the streak calendar, plus friends' streaks. With
/// [sample], the made-up history that goes with the sample prompts.
Future<StreakHistory> getStreakHistory(
    FirebaseFirestore firestore, String uid, String username,
    {bool sample = false}) async {
  if (sample) {
    return sampleStreakHistory(DateTime.now().toUtc(), username);
  }
  // TODO(cloud): standings: streak.current from each friend's
  // FriendView/profile, by uid (needs friends stored by uid, TODO.md
  // Prerequisites). Cache for the day: about two reads per friend (doc +
  // friend check). Until then the standings section is hidden.
  final record = await getStreakRecord(firestore, uid);
  return StreakHistory(answeredDays: record.answeredDays);
}

/// Days in a row the user has answered at least one prompt
Future<int> getAnswerStreak(FirebaseFirestore firestore, String uid) async {
  final record = await getStreakRecord(firestore, uid);
  return record.currentAsOf(promptDayId(DateTime.now().toUtc()));
}

/// 1234 -> "1.2k", for tight stat tiles
String compactCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) {
    final k = n / 1000;
    return '${k >= 100 ? k.round() : k.toStringAsFixed(1).replaceAll('.0', '')}k';
  }
  final m = n / 1000000;
  return '${m.toStringAsFixed(1).replaceAll('.0', '')}M';
}
