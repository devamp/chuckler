import 'package:chuckler/data/friend_prompts.dart';
import 'package:chuckler/data/prompt_stats.dart';
import 'package:chuckler/data/prompts.dart';
import 'package:chuckler/database/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  const day = '2026-11-09';
  final me = DbUser('me', 'caden', 0, 0, '');

  setUp(() => firestore = FakeFirebaseFirestore());

  Map<String, dynamic> prompt(String uid, String name, List<String>? audience,
          DateTime at, {String dayId = day}) =>
      {
        'before': '$name asks ',
        'after': '.',
        'kind': 'fill',
        'dayId': dayId,
        'createdAt': Timestamp.fromDate(at),
        'creator': {'uid': uid, 'username': name, 'photoUrl': ''},
        'status': 'active',
        'counts': {'answers': 2, 'likes': 1, 'dislikes': 0},
        'likedBy': ['ben'],
        if (audience != null) 'audience': audience,
      };

  test('createFriendPrompt writes one prompt a day without an audience',
      () async {
    final p = await createFriendPrompt(firestore, me, ' My dog ', 'snacks', day);
    expect(p.promptId, 'me_$day');
    expect(p.promptDateId, day);
    expect(isFriendPrompt(p), isTrue);
    expect(isLocalPrompt(p), isFalse);
    expect(p.creatorUsername, 'caden');
    final doc = await firestore.doc('FriendPrompts/me_$day').get();
    expect(doc.data()!['before'], 'My dog ');
    expect(doc.data()!['after'], ' snacks');
    expect(doc.data()!['status'], 'active');
    expect(doc.data()!.containsKey('audience'), isFalse);
  });

  test('getFriendPrompts: mine and those I\'m in, oldest first', () async {
    await firestore.doc('FriendPrompts/ben_$day').set(
        prompt('ben', 'ben', ['ben', 'me'], DateTime.utc(2026, 11, 9, 8)));
    await firestore.doc('FriendPrompts/cleo_$day').set(
        prompt('cleo', 'cleo', ['cleo', 'me'], DateTime.utc(2026, 11, 9, 7)));
    // not for me
    await firestore.doc('FriendPrompts/dev_$day').set(
        prompt('dev', 'dev', ['dev'], DateTime.utc(2026, 11, 9, 6)));
    // yesterday's
    await firestore.doc('FriendPrompts/ben_2026-11-08').set(prompt(
        'ben', 'ben', ['ben', 'me'], DateTime.utc(2026, 11, 8, 8),
        dayId: '2026-11-08'));
    // mine, before the function has set its audience
    await firestore.doc('FriendPrompts/me_$day').set(
        prompt('me', 'caden', null, DateTime.utc(2026, 11, 9, 9)));

    final ps = await getFriendPrompts(firestore, 'me', day);
    expect(ps.map((p) => p.promptId), ['cleo_$day', 'ben_$day', 'me_$day']);
    expect(ps.every(isFriendPrompt), isTrue);
    expect(ps.first.creatorUsername, 'cleo');
    expect(ps.first.location, 'friends');
    expect(ps.first.responses, 2);
  });

  test('stats and likes use the friend prompt doc', () async {
    await firestore.doc('FriendPrompts/ben_$day').set(
        prompt('ben', 'ben', ['ben', 'me'], DateTime.utc(2026, 11, 9, 8)));
    final p = (await getFriendPrompts(firestore, 'me', day)).single;
    expect(promptRef(firestore, p).path, 'FriendPrompts/ben_$day');
    final stats = await getPromptStats(firestore, 'me', p, null);
    expect(stats.answers, 2);
    expect(stats.likes, 1);
    await likePrompt(firestore, 'me', p, true);
    final after = await getPromptStats(firestore, 'me', p, null);
    expect(after.likes, 2);
    expect(after.likedByMe, isTrue);
  });

  test('daily prompts are not friend prompts', () {
    final daily = promptFromDoc(day, 'p1', {
      'before': 'x',
      'creator': {'uid': 'chuckler', 'username': 'Chuckler'},
    });
    expect(isFriendPrompt(daily), isFalse);
  });
}
