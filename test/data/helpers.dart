import 'package:chuckler/data/matchups.dart';
import 'package:chuckler/data/prompt_day.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Some queries fire writes without awaiting them; give those time to land.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

Map<String, dynamic> userDoc({
  String username = 'alice',
  int posts = 3,
  int friends = 0,
  int pendingFriends = 0,
  List<String>? friendsList,
  List<String>? pendingFriendsList,
  String profileImage = 'https://example.com/a.png',
}) {
  return {
    'username': username,
    'posts': posts,
    'friends': friends,
    'pendingFriends': pendingFriends,
    'profileImage': profileImage,
    if (friendsList != null) 'friendsList': friendsList,
    if (pendingFriendsList != null) 'pendingFriendsList': pendingFriendsList,
  };
}

Map<String, dynamic> postDoc({
  required String promptId,
  required String promptDateId,
  required DateTime date,
  String uid = 'u1',
  String username = 'alice',
  String answer = 'an answer',
}) {
  return {
    'answer': answer,
    'username': username,
    'uid': uid,
    'likes': 1,
    'dislikes': 2,
    'wins': 3,
    'promptId': promptId,
    'promptDateId': promptDateId,
    'date': Timestamp.fromDate(date),
  };
}

/// A MatchUps doc as createMatchup writes it, from a Matchup
Map<String, dynamic> matchupDoc(Matchup m,
    {required String dayId, required DateTime createdAt}) {
  return {
    'promptDateId': dayId,
    'promptId': m.promptId,
    'before': m.promptBefore,
    'after': m.promptAfter,
    'segment': m.segment.name,
    if (m.scope == MatchupScope.friends) 'scope': 'friends',
    'createdAt': Timestamp.fromDate(createdAt),
    'status': 'active',
    'postIds': [for (final a in m.answers) a.postId],
    'answers': [
      for (final a in m.answers)
        {
          'postId': a.postId,
          'answer': a.answer,
          'wins': a.wins,
          'dislikes': a.downvotes,
          'commentCount': a.commentCount,
          'preview': [
            for (final p in a.preview) {'username': p.username, 'text': p.text}
          ],
        }
    ],
  };
}

/// Writes matchups into the fake Firestore for today's prompt day, in order,
/// with a Posts doc for each answer unless [posts] is false
Future<void> seedMatchups(FirebaseFirestore firestore, List<Matchup> matchups,
    {DateTime? now, bool posts = true}) async {
  final t = (now ?? DateTime.now()).toUtc();
  final dayId = promptDayId(t);
  for (var i = 0; i < matchups.length; i++) {
    if (posts) {
      for (final a in matchups[i].answers) {
        await firestore.collection('Posts').doc(a.postId).set({
          'answer': a.answer,
          'counts': {'dislikes': a.downvotes, 'wins': a.wins},
        });
      }
    }
    await firestore.collection('MatchUps').doc(matchups[i].id).set(matchupDoc(
        matchups[i],
        dayId: dayId,
        createdAt: t.subtract(Duration(minutes: matchups.length - i))));
  }
}
