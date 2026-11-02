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
