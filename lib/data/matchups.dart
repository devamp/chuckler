import 'package:cloud_firestore/cloud_firestore.dart';
import 'posts.dart' show historyRef;
import 'prompt_day.dart';

// Swipe voting on the Home tab, on the layout in docs/data-model.md
// (MatchUps, Votes, Dislikes). Matchups are written by the createMatchup
// Cloud Function and carry no uids or usernames, so vote cards are anonymous
// until the user votes; then getMatchupAuthors reveals who wrote each one.
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
/// Whom a matchup's prompt is for
enum MatchupScope { public, friends }

/// The Home tab's filter
enum MatchupFilter {
  all('All', 'Everything to vote on'),
  global('Global', 'Public daily prompts'),
  friends('Friends', 'Prompts your friends wrote');

  final String label;
  final String description;
  const MatchupFilter(this.label, this.description);

  bool shows(Matchup m) => switch (this) {
        MatchupFilter.all => true,
        MatchupFilter.global => m.scope == MatchupScope.public,
        MatchupFilter.friends => m.scope == MatchupScope.friends,
      };
}

class Matchup {
  final String id;
  final String promptId;
  final String promptDateId;
  final String promptBefore;
  final String promptAfter;
  final Segment segment;

  /// whom the prompt is for: public (daily prompts) or friends (a prompt a
  /// friend wrote, for their friends only). Missing means public.
  final MatchupScope scope;

  /// answers[0] is the top card, answers[1] the bottom card
  final List<MatchupAnswer> answers;

  /// "active", or "hidden" once reports took it down
  final String status;

  Matchup({
    required this.id,
    required this.promptId,
    required this.promptDateId,
    required this.promptBefore,
    required this.promptAfter,
    required this.segment,
    this.scope = MatchupScope.public,
    this.status = 'active',
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
      scope: data['scope'] == 'friends'
          ? MatchupScope.friends
          : MatchupScope.public,
      status: data['status'] as String? ?? 'active',
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

/// Who wrote one answer, shown once the user has voted on the matchup
class MatchupAuthor {
  final String username;

  /// '' when the author has no photo
  final String photoUrl;

  const MatchupAuthor(this.username, this.photoUrl);
}

/// Both answers' authors, in card order, from MatchUps/{id}/Authors/names.
/// Only readable after the user's vote is saved; null if it's missing or
/// the read is refused.
Future<List<MatchupAuthor>?> getMatchupAuthors(
    FirebaseFirestore firestore, String matchupId) async {
  try {
    final doc = await firestore
        .collection('MatchUps')
        .doc(matchupId)
        .collection('Authors')
        .doc('names')
        .get();
    final answers = (doc.data()?['answers'] as List?) ?? const [];
    if (answers.length != 2) return null;
    return [
      for (final a in answers)
        MatchupAuthor(
            (a as Map)['username'] as String? ?? '', a['photoUrl'] as String? ?? ''),
    ];
  } catch (e) {
    return null;
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
  // Two queries, since the rules let you read a friend prompt's matchups
  // only if you're in its audience, and a query must say which it wants:
  // public ones, and friend prompts' ones you're in the audience of.
  final today = firestore
      .collection('MatchUps')
      .where('promptDateId', isEqualTo: dayId);
  final results = await Future.wait([
    today
        .where('scope', isEqualTo: 'public')
        .orderBy('createdAt')
        .limit(matchupPageSize)
        .get(),
    today
        .where('audience', arrayContains: uid)
        .orderBy('createdAt')
        .limit(matchupPageSize)
        .get(),
    // all of today's answers, friend prompts included, so the queue leaves
    // out matchups with the user's own answers (one read)
    historyRef(firestore, uid, dayId).get(),
  ]);
  final mine = {...myPostIds};
  final history = (results[2] as DocumentSnapshot<Map<String, dynamic>>)
          .data()?['answers'] as Map<String, dynamic>? ??
      const {};
  for (final e in history.values) {
    if (e is Map && e['promptDateId'] == dayId && e['postId'] is String) {
      mine.add(e['postId'] as String);
    }
  }
  final docs = [
    ...(results[0] as QuerySnapshot<Map<String, dynamic>>).docs,
    ...(results[1] as QuerySnapshot<Map<String, dynamic>>).docs,
  ]..sort((a, b) {
      final ta = a.data()['createdAt'] as Timestamp?;
      final tb = b.data()['createdAt'] as Timestamp?;
      if (ta == null || tb == null) return 0;
      return ta.compareTo(tb);
    });
  final matchups = docs;
  // one read per vote today; the vote doc ids are matchupId_uid
  final votes = await firestore
      .collection('Votes')
      .where('uid', isEqualTo: uid)
      .where('promptDateId', isEqualTo: dayId)
      .get();
  final voted = {for (final v in votes.docs) v.data()['matchupId'] as String?};

  return [
    for (final doc in matchups)
      if (!voted.contains(doc.id))
        if (Matchup.fromDoc(doc.id, doc.data()) case final m?)
          // hidden: taken down after reports
          if (!m.includesAnyPost(mine) && m.status != 'hidden') m,
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

/// The prompts the user hid from their Home queue: Private/hiddenPrompts,
/// `{dayId, promptIds}`. Prompts last a day, so it holds only one day's
/// list; a list from an earlier day reads as empty and is replaced on the
/// next hide. Only the Home tab uses it: the Create tab still shows them.
DocumentReference<Map<String, dynamic>> hiddenPromptsRef(
        FirebaseFirestore firestore, String uid) =>
    firestore
        .collection('Users')
        .doc(uid)
        .collection('Private')
        .doc('hiddenPrompts');

/// The prompt ids hidden for [dayId] (one read)
Future<Set<String>> getHiddenPrompts(
    FirebaseFirestore firestore, String uid, String dayId) async {
  final data = (await hiddenPromptsRef(firestore, uid).get()).data();
  if (data == null || data['dayId'] != dayId) return {};
  return {...((data['promptIds'] as List?) ?? const []).whereType<String>()};
}

/// Saves the prompts hidden for [dayId], replacing any earlier day's list
Future<void> saveHiddenPrompts(FirebaseFirestore firestore, String uid,
    String dayId, Set<String> promptIds) {
  return hiddenPromptsRef(firestore, uid).set({
    'dayId': dayId,
    'promptIds': promptIds.toList()..sort(),
  });
}

/// A prompt the user hid from Home, with its text for the Settings list
class HiddenPrompt {
  final String promptId;
  final String before;
  final String after;

  const HiddenPrompt(this.promptId, this.before, this.after);
}

/// The prompts hidden for [dayId] with their text: daily prompts from
/// PromptDays, friend prompts (ids `{uid}_{dayId}`) from FriendPrompts. One
/// read for the list and one per prompt; an unreadable prompt is listed
/// without text.
Future<List<HiddenPrompt>> getHiddenPromptDetails(
    FirebaseFirestore firestore, String uid, String dayId) async {
  final ids = (await getHiddenPrompts(firestore, uid, dayId)).toList()..sort();
  return Future.wait(ids.map((id) async {
    try {
      final ref = id.endsWith('_$dayId')
          ? firestore.collection('FriendPrompts').doc(id)
          : firestore
              .collection('PromptDays')
              .doc(dayId)
              .collection('Prompts')
              .doc(id);
      final data = (await ref.get()).data() ?? const {};
      return HiddenPrompt(id, data['before'] as String? ?? '',
          data['after'] as String? ?? '');
    } catch (e) {
      return HiddenPrompt(id, '', '');
    }
  }));
}
