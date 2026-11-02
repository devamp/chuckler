import 'package:cloud_firestore/cloud_firestore.dart';
import 'sample_matchups.dart';

// Swipe voting on the Home tab. This file runs on sample data for now; the
// TODO(cloud) notes list what the real queries and Cloud Functions need.
//
// TODO(cloud): MatchUps documents (written by createMatchup in
// functions/index.js) are missing fields the voting screen needs:
//   - downvotes1 / downvotes2 counters (only wins1 / wins2 exist)
//   - a created date, to order matchups and to scope "today"
//   - the prompt's before/after text, or the app must join each matchup with
//     PromptDays/{promptDateId}/Prompts/{promptId}
//   - the prompt's segment (friends / local / global)
// createMatchup should also pair posts inside a transaction: two posts
// created at the same moment can currently claim the same unmatched post.

/// Which kind of prompt a matchup belongs to. Friends and local are relative
/// to the viewer, so the real value is worked out per viewer.
enum Segment { friends, local, global }

/// One of the two answers in a matchup
class MatchupAnswer {
  final String postId;
  final String uid;
  final String username;
  final String answer;
  int wins;
  int downvotes;

  MatchupAnswer({
    required this.postId,
    required this.uid,
    required this.username,
    required this.answer,
    this.wins = 0,
    this.downvotes = 0,
  });
}

/// Two answers to the same prompt, shown as stacked cards
class Matchup {
  final String id;
  final String promptId;
  final String promptDateId;
  final String promptBefore;
  final String promptAfter;
  final Segment segment;

  /// answers[0] is the top card, answers[1] the bottom card
  final List<MatchupAnswer> answers;

  Matchup({
    required this.id,
    required this.promptId,
    required this.promptDateId,
    required this.promptBefore,
    required this.promptAfter,
    required this.segment,
    required MatchupAnswer top,
    required MatchupAnswer bottom,
  }) : answers = [top, bottom];

  bool includesUser(String uid) => answers.any((a) => a.uid == uid);

  /// Share of wins that went to answers[card], rounded to a whole percent.
  /// Downvotes don't count toward either side.
  int pickPercent(int card) {
    final total = answers[0].wins + answers[1].wins;
    if (total == 0) return 0;
    return (answers[card].wins * 100 / total).round();
  }
}

enum VoteType { win, downvote }

/// A user's single, final action on a matchup
class MatchupVote {
  /// 0 for the top card, 1 for the bottom card
  final int card;
  final VoteType type;

  const MatchupVote(this.card, this.type);
}

/// Matchups to vote on today, across all of today's prompts.
Future<List<Matchup>> getVotingMatchups(
    FirebaseFirestore firestore, String uid) async {
  // TODO(cloud): replace the sample data with a MatchUps query.
  //   - Query MatchUps where promptDateId == today's PromptDays id (needs an
  //     index on promptDateId, plus the ranking field once ranking exists).
  //   - Drop matchups that include the user's own answer. Firestore can't
  //     express "uid1 != me and uid2 != me", so filter after the query.
  //   - Drop matchups the user already voted on: read Votes where
  //     uid == me and promptDateId == today, so Votes docs need promptDateId.
  //   - Decide a page size and load more as the queue runs low.
  return sampleMatchups();
}

/// Records a vote. Votes are final, so a second vote on the same matchup
/// must be refused.
Future<void> castVote(FirebaseFirestore firestore, String uid,
    Matchup matchup, MatchupVote vote) async {
  // TODO(cloud): write Votes/{matchupId}_{uid} with
  //   {uid, matchupId, promptDateId, card, type ('win' | 'downvote'), date}.
  //   - Firestore rules: allow create when request.auth.uid == uid and the
  //     doc does not exist; never allow update or delete.
  //   - Counters: a Cloud Function on Votes create should increment the
  //     matchup's wins1/wins2/downvotes1/downvotes2, so clients can't edit
  //     counts directly (rules then deny client writes to those fields).
}
