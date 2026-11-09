// Tests for lib/data/comments.dart (answer comments in CommentPages) against
// fake_cloud_firestore. Who may comment is covered by the rules tests.

import 'package:chuckler/data/comments.dart';
import 'package:chuckler/database/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  final alice = DbUser('u-alice', 'alice', 0, 0, '');
  CollectionReference<Map<String, dynamic>> pages() =>
      firestore.collection('Posts').doc('p1').collection('CommentPages');

  setUp(() => firestore = FakeFirebaseFirestore());

  test('an empty thread has no pages and starts page 0', () async {
    final t = await getCommentThread(firestore, 'p1');
    expect(t.comments, isEmpty);
    expect(t.pages, 0);
    expect(t.nextPageId, '0');
  });

  test('addComment writes one keyed comment and names it in last', () async {
    var t = await getCommentThread(firestore, 'p1');
    final c = await addComment(firestore, alice, t, 'm1', '  so true  ');

    expect(c.text, 'so true');
    final page = (await pages().doc('0').get()).data()!;
    expect(page['last'], c.id);
    final stored = page['comments'][c.id];
    expect(stored['uid'], 'u-alice');
    expect(stored['username'], 'alice');
    expect(stored['text'], 'so true');
    expect(stored['matchupId'], 'm1');
    expect(stored['at'], isA<Timestamp>());

    // a second comment joins the same page
    t = await getCommentThread(firestore, 'p1');
    await addComment(firestore, alice, t, 'm1', 'again');
    t = await getCommentThread(firestore, 'p1');
    expect(t.pages, 1);
    expect(t.comments.map((c) => c.text), ['so true', 'again']);
  });

  test('reads every page, oldest comment first', () async {
    await pages().doc('1').set({
      'comments': {
        'b': {'uid': 'x', 'username': 'ben', 'text': 'second',
          'at': Timestamp.fromDate(DateTime.utc(2026, 11, 8, 12))},
      },
    });
    await pages().doc('0').set({
      'comments': {
        'a': {'uid': 'y', 'username': 'cleo', 'text': 'first',
          'at': Timestamp.fromDate(DateTime.utc(2026, 11, 8, 11))},
      },
    });
    final t = await getCommentThread(firestore, 'p1');
    expect(t.comments.map((c) => '${c.username}: ${c.text}'),
        ['cleo: first', 'ben: second']);
    expect(t.pages, 2);
    expect(t.lastPageSize, 1);
    expect(t.nextPageId, '1');
  });

  test('a full page starts the next one', () {
    const full = CommentThread('p1', [], 3, commentsPerPage);
    expect(full.nextPageId, '3');
    const roomy = CommentThread('p1', [], 3, 10);
    expect(roomy.nextPageId, '2');
  });
}
