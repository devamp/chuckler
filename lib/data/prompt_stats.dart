import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../database/models.dart';
import 'matchups.dart';
import 'sample_prompts.dart';

// Stats shown on the Create tab for each prompt. Only the answer count is
// live today (PromptDays/{promptDateId}/Prompts/{promptId}.responses, bumped
// by the incrementPrompt Cloud Function). Debug builds fill the rest with
// sample numbers; release builds show zeros until the TODO(cloud) work lands.
//
// TODO(cloud): the layout is in docs/data-model.md. Stats need these
// server-side counts:
//   - Prompts/{promptId}.counts: answers (by a function), likes (written by
//     the app with likedBy) and dislikes (written by the app with an
//     anonymous Dislikes doc); see likePrompt below.
//   - Posts/{postId}.counts: matchups (times paired, not views; views are
//     not counted), votes, wins, dislikes. Totalled by the checkpoint
//     function rather than on every vote, to save writes.
//   - Posts/{postId}.winsByHour: a map of hour -> wins. Feeds the bar chart.
//   - Posts/{postId}.rank: written by the checkpoint function (TODO.md
//     section 4), ranked by rate rather than raw counts.
//   - Users/{uid}/FriendView/profile.streak: {days, from, current, longest},
//     where days is a string with one 1 or 0 per prompt day. Updated in a
//     transaction by the Posts-create function, so clients never write
//     their own streak. Feeds the streak chip and the calendar.
// Clients only read these; Firestore rules should deny client writes to them.

/// Which segment a prompt belongs to, from PromptDays/.../Prompts.type.
/// Unknown or missing types count as global, the only kind that exists today.
Segment segmentOf(DbPrompt prompt) {
  return switch (prompt.type?.toLowerCase()) {
    'friends' => Segment.friends,
    'local' => Segment.local,
    _ => Segment.global,
  };
}

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
}

/// Stats for one prompt. myPost is the user's answer, or null.
Future<PromptStats> getPromptStats(FirebaseFirestore firestore, String uid,
    DbPrompt prompt, DbPost? myPost) async {
  if (isSamplePrompt(prompt) || kDebugMode) {
    return samplePromptStats(prompt, myPost);
  }
  // TODO(cloud): read the counters listed at the top of this file:
  //   - prompt totals from PromptDays/{promptDateId}/Prompts/{promptId}
  //     (prompt.responses already holds the answer count from login)
  //   - likedByMe: whether the prompt's likedBy contains uid (no extra read)
  //   - the user's answer from Posts/{myPost.postId}
  //   - friends who answered: Posts where promptDateId and promptId match
  //     and uid is in the user's friends, chunked by 30 for whereIn. Needs
  //     friends stored by uid first (TODO.md, Prerequisites). Posts are
  //     friends-only, so check in the emulator that the rules allow this
  //     query (docs/data-model.md, Rules).
  return PromptStats(
    answers: prompt.responses,
    mine: myPost == null ? null : AnswerStats(wins: myPost.wins ?? 0),
  );
}

/// Likes or unlikes a prompt for the user
Future<void> likePrompt(FirebaseFirestore firestore, String uid,
    DbPrompt prompt, bool liked) async {
  // TODO(cloud): one update to PromptDays/{promptDateId}/Prompts/{promptId}:
  // likedBy arrayUnion(uid) (arrayRemove to unlike), counts.likes +1 / -1,
  // Prompts can also be disliked, anonymously: create
  // Dislikes/{promptId}_{uid} and bump counts.dislikes in one batch. Rules allow only those fields, only the
  // writer's own uid, and counts equal to the list sizes. No Cloud Function
  // needed. Remember the user's likes on the phone (Isar) for the "what I
  // liked" list; see docs/data-model.md, Likes and dislikes.
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

/// Answered days for the streak calendar, plus friends' streaks
Future<StreakHistory> getStreakHistory(
    FirebaseFirestore firestore, String uid, String username) async {
  // TODO(cloud):
  //   - answeredDays: decode streak.days and streak.from from the user's
  //     FriendView/profile, which login already reads, so no extra reads.
  //     Days after the end of the string are missed days.
  //   - standings: streak.current from each friend's FriendView/profile, by
  //     uid (needs friends stored by uid, TODO.md Prerequisites). Cache for
  //     the day: it costs about two reads per friend (doc + friend check).
  if (kDebugMode) {
    return sampleStreakHistory(DateTime.now().toUtc(), username);
  }
  return const StreakHistory();
}

/// Days in a row the user has answered at least one prompt
Future<int> getAnswerStreak(FirebaseFirestore firestore, String uid) async {
  // TODO(cloud): read streak.current from Users/{uid}/FriendView/profile
  // (see the top of this file); show 0 if the string ends before yesterday.
  return kDebugMode ? sampleStreak : 0;
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
