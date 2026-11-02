import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';

//TODO LOOK AT IMPLEMENTING A DEBOUNCER TO PREVENT READ ABUSE

/// @author Caden Deutscher
/// @description - adds a comment to the subcollection 'Comments' in both the user and post objects
Future<void> addCommentToPost(FirebaseFirestore firestore, String postId,
    String usernameCommenter, String comment) async {
  DateTime now = DateTime.now().toUtc();

  final timestamp = Timestamp.fromDate(now);
  try {
    // Reference the comments subcollection within the post document
    final pCommentsRef = firestore.collection('Comments');

    // Create a new document within the comments subcollection
    await pCommentsRef.add({
      'username': usernameCommenter,
      'comment': comment,
      'postId': postId,
      'date': timestamp
    });
  } catch (e) {
    print('Error adding comment: $e');
  }
}

/// Description: Get the first few comments from a post
Future<List<DbComment>> getComments(
    FirebaseFirestore firestore, String postId) async {
  List<DbComment> comments = List<DbComment>.empty(growable: true);
  try {
    QuerySnapshot querySnapshot = await firestore
        .collection('Comments')
        .where('postId', isEqualTo: postId)
        .limit(5)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("STILL EMPTY");
      return comments;
    } else {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        dynamic comment = data['comment'];
        dynamic username = data['username'];
        comments.add(DbComment(username, comment));
      }
    }
  } catch (error) {}
  return comments;
}
