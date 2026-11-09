import 'package:cloud_firestore/cloud_firestore.dart';
import 'prompt_day.dart';

// Swipe voting on the Home tab, on the layout in docs/data-model.md
// (MatchUps, Votes, Dislikes). Matchups are written by the createMatchup
// Cloud Function and carry no uids or usernames, so vote cards are anonymous.
//
// Still to come:
//   - ranking: order matchups by score instead of age, once checkpoints
//     exist (TODO.md section 4)
//   - paging: load the next 50 when the queue runs low
//   - friends-only matchups for friend prompts (needs friends by uid)

/// Which kind of prompt a matchup belongs to. Friends and local are relative
/// to the viewer, so the real value is worked out per viewer.
enum Segment { friends, local, global }

/// A prompt's or matchup's stored location as a segment. Unknown or missing
/// values count as global.
Segment parseSegment(String? location) => switch (location?.toLowerCase()) {
      'friends' => Segment.friends,
      'local' => Segment.local,
      _ => Segment.global,
    };

/// One of the latest comments on an answer, copied into the matchup
class CommentPreview {
  final String username;
  final String text;

  const CommentPreview(this.username, this.text);
}

/// One of the two answers in a matchup. No author: votes are anonymous.
class MatchupAnswer {
  final String postId;
  final String answer;
  int wins;
  int downvotes;
  final int commentCount;
  final List<CommentPreview> preview;

  MatchupAnswer({
    required this.postId,
    required this.answer,
    this.wins = 0,
    this.downvotes = 0,
    this.commentCount = 0,
    this.preview = const [],
  });

  factory MatchupAnswer.fromMap(Map<String, dynamic> m) => MatchupAnswer(
        postId: m['postId'] as String? ?? '',
        answer: m['answer'] as String? ?? '',
        wins: (m['wins'] as num?)?.toInt() ?? 0,
        downvotes: (m['dislikes'] as num?)?.toInt() ?? 0,
        commentCount: (m['commentCount'] as num?)?.toInt() ?? 0,
        preview: [
          for (final p in (m['preview'] as List?) ?? const [])
            if (p is Map)
              CommentPreview(
                  p['username'] as String? ?? '', p['text'] as String? ?? ''),
        ],
      );
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

  /// A MatchUps doc, or null if it doesn't hold two answers
  static Matchup? fromDoc(String id, Map<String, dynamic> data) {
    final answers = (data['answers'] as List?) ?? const [];
    if (answers.length != 2 || answers.any((a) => a is! Map)) return null;
    return Matchup(
      id: id,
      promptId: data['promptId'] as String? ?? '',
      promptDateId: data['promptDateId'] as String? ?? '',
      promptBefore: data['before'] as String? ?? '',
      promptAfter: data['after'] as String? ?? '',
      segment: parseSegment(data['segment'] as String?),
      top: MatchupAnswer.fromMap(Map<String, dynamic>.from(answers[0])),
      bottom: MatchupAnswer.fromMap(Map<String, dynamic>.from(answers[1])),
    );
  }

  /// One of the user's own answers is in this matchup
  bool includesAnyPost(Set<String> postIds) =>
      answers.any((a) => postIds.contains(a.postId));

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

/// How many matchups one load fetches
const int matchupPageSize = 50;

/// Today's matchups the user can still vote on, oldest first: not ones with
/// their own answers (myPostIds) and not ones they already voted on.
Future<List<Matchup>> getVotingMatchups(
    FirebaseFirestore firestore, String uid, Set<String> myPostIds,
    {DateTime? now}) async {
  final dayId = promptDayId((now ?? DateTime.now()).toUtc());
  final matchups = await firestore
      .collection('MatchUps')
      .where('promptDateId', isEqualTo: dayId)
      .orderBy('createdAt')
      .limit(matchupPageSize)
      .get();
  // one read per vote today; the vote doc ids are matchupId_uid
  final votes = await firestore
      .collection('Votes')
      .where('uid', isEqualTo: uid)
      .where('promptDateId', isEqualTo: dayId)
      .get();
  final voted = {for (final v in votes.docs) v.data()['matchupId'] as String?};

  return [
    for (final doc in matchups.docs)
      if (!voted.contains(doc.id))
        if (Matchup.fromDoc(doc.id, doc.data()) case final m?)
          if (!m.includesAnyPost(myPostIds)) m,
  ];
}

/// Records a vote, final once written: the rules refuse a second vote on the
/// same matchup. A downvote also leaves an anonymous dislike on that answer
/// (Dislikes/{postId}_{uid} plus the post's counts.dislikes, in the same
/// batch). The onVoteCreated Cloud Function then counts the vote on the
/// matchup and the answers. Throws if the write is refused.
Future<void> castVote(FirebaseFirestore firestore, String uid,
    Matchup matchup, MatchupVote vote) async {
  final dislike = vote.type == VoteType.downvote;
  final postId = matchup.answers[vote.card].postId;
  final batch = firestore.batch();
  batch.set(firestore.collection('Votes').doc('${matchup.id}_$uid'), {
    'uid': uid,
    'matchupId': matchup.id,
    'card': vote.card,
    'type': dislike ? 'dislike' : 'win',
    'promptDateId': matchup.promptDateId,
    'at': FieldValue.serverTimestamp(),
  });
  if (dislike) {
    batch.set(firestore.collection('Dislikes').doc('${postId}_$uid'), {
      'uid': uid,
      'targetId': postId,
      'targetType': 'post',
      'matchupId': matchup.id,
      'at': FieldValue.serverTimestamp(),
    });
    batch.update(firestore.collection('Posts').doc(postId),
        {'counts.dislikes': FieldValue.increment(1)});
  }
  await batch.commit();
}
