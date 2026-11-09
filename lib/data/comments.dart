import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';

// Comments belong to an answer, not a matchup, so one thread follows the
// answer through every matchup it's in. They're stored in pages under the
// post, about 200 per page, so reading a thread costs one read per page:
//   Posts/{postId}/CommentPages/{n}
//     comments: { "<id>": { uid, username, text, matchupId, at } }
//     last: "<id of the comment added most recently>"
// Only someone who voted on a matchup containing the answer can comment
// (firestore.rules). The onCommentPageWritten Cloud Function keeps the
// post's and its matchups' commentCount and preview. See docs/data-model.md.

/// Comments per page before a new page starts
const int commentsPerPage = 200;

/// Longest comment the rules accept
const int maxCommentLength = 500;

class AnswerComment {
  final String id;
  final String uid;
  final String username;
  final String text;

  /// null until the server has stamped it
  final DateTime? at;

  const AnswerComment(this.id, this.uid, this.username, this.text, this.at);
}

/// An answer's comments, oldest first, and where the next one goes
class CommentThread {
  final String postId;
  final List<AnswerComment> comments;

  /// number of pages, and comments on the last one
  final int pages;
  final int lastPageSize;

  const CommentThread(
      this.postId, this.comments, this.pages, this.lastPageSize);

  /// the page a new comment is added to
  String get nextPageId =>
      (pages == 0 || lastPageSize >= commentsPerPage ? pages : pages - 1)
          .toString();
}

CollectionReference<Map<String, dynamic>> _pages(
        FirebaseFirestore firestore, String postId) =>
    firestore.collection('Posts').doc(postId).collection('CommentPages');

/// Reads an answer's whole thread: one read per page.
Future<CommentThread> getCommentThread(
    FirebaseFirestore firestore, String postId) async {
  final snap = await _pages(firestore, postId).get();
  // page ids are "0", "1", … so sort them as numbers
  final pages = snap.docs.toList()
    ..sort((a, b) =>
        (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
  final comments = <AnswerComment>[];
  var lastPageSize = 0;
  for (final page in pages) {
    final map = (page.data()['comments'] as Map?) ?? const {};
    lastPageSize = map.length;
    map.forEach((id, c) {
      if (c is! Map) return;
      comments.add(AnswerComment(
        id as String,
        c['uid'] as String? ?? '',
        c['username'] as String? ?? '',
        c['text'] as String? ?? '',
        (c['at'] as Timestamp?)?.toDate(),
      ));
    });
  }
  comments.sort((a, b) =>
      (a.at ?? DateTime(9999)).compareTo(b.at ?? DateTime(9999)));
  return CommentThread(postId, comments, pages.length, lastPageSize);
}

/// Adds the user's comment to the thread's latest page (starting a new page
/// when it's full) and returns it. matchupId is the matchup the user voted
/// on, which the rules check. Throws if the write is refused.
Future<AnswerComment> addComment(FirebaseFirestore firestore, DbUser user,
    CommentThread thread, String matchupId, String text) async {
  final uid = user.uid ?? '';
  final trimmed = text.trim();
  final id = firestore.collection('Posts').doc().id;
  await _pages(firestore, thread.postId).doc(thread.nextPageId).set({
    'comments': {
      id: {
        'uid': uid,
        'username': user.username ?? '',
        'text': trimmed,
        'matchupId': matchupId,
        'at': FieldValue.serverTimestamp(),
      },
    },
    'last': id,
  }, SetOptions(merge: true));
  return AnswerComment(id, uid, user.username ?? '', trimmed, DateTime.now());
}
