// Characterization tests for lib/data/comments.dart.
//
// These describe what the queries do today, not what they should do. Where
// today's behavior looks like a bug, the test still matches it and carries a
// TODO so the bug can be fixed deliberately later.

import 'package:chuckler/data/comments.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  group('comments', () {
    test('addCommentToPost writes a comment for the post', () async {
      await addCommentToPost(firestore, 'post1', 'alice', 'lol');

      final comments = await firestore.collection('Comments').get();
      final c = comments.docs.single.data();
      expect(c['postId'], 'post1');
      expect(c['username'], 'alice');
      expect(c['comment'], 'lol');
      expect(c['date'], isA<Timestamp>());
    });

    test('getComments returns up to 5 comments for the post', () async {
      for (var i = 0; i < 7; i++) {
        await addCommentToPost(firestore, 'post1', 'user$i', 'comment $i');
      }
      await addCommentToPost(firestore, 'post2', 'zed', 'elsewhere');

      final comments = await getComments(firestore, 'post1');

      expect(comments, hasLength(5));
      expect(comments.every((c) => c.comment!.startsWith('comment ')), isTrue);
      expect(comments.first.username, startsWith('user'));
    });

    test('getComments returns an empty list when there are none', () async {
      expect(await getComments(firestore, 'post1'), isEmpty);
    });
  });
}
