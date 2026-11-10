// LeaderboardService: which board shows, and loading friends boards
// together and global boards one at a time.

import 'package:chuckler/data/friends.dart';
import 'package:chuckler/data/leaderboards.dart';
import 'package:chuckler/state/leaderboard_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const me = FriendCard('u1', 'ava', '');
  late FakeFirebaseFirestore firestore;
  late LeaderboardService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = LeaderboardService();
    await firestore.doc('Users/u1/FriendView/profile').set({
      'stats': {'answers': 2, 'wins': 1},
    });
    await firestore.doc('Leaderboards/wins-all').set({
      'entries': [
        {'username': 'gus', 'photoUrl': '', 'value': 8},
      ],
    });
  });

  test('starts on friends top answers this week', () {
    expect(service.scope, LeaderScope.friends);
    expect(service.board, LeaderBoard.answers);
    expect(service.period, LeaderPeriod.week);
    expect(service.current, isNull);
  });

  test('friends boards load together', () async {
    await service.ensureLoaded(firestore, me, const []);
    service.setBoard(LeaderBoard.posts);
    service.setPeriod(LeaderPeriod.all);
    expect(service.currentId, 'posts-all');
    expect(service.current!.entries.single.value, 2);
  });

  test('global boards load one at a time and refresh with force',
      () async {
    service.setScope(LeaderScope.global);
    service.setBoard(LeaderBoard.wins);
    service.setPeriod(LeaderPeriod.all);
    await service.ensureLoaded(firestore, me, const []);
    expect(service.current!.entries.single.username, 'gus');

    service.setBoard(LeaderBoard.streak);
    expect(service.current, isNull, reason: 'not loaded yet');
    await service.ensureLoaded(firestore, me, const []);
    expect(service.current!.isEmpty, isTrue);

    service.setBoard(LeaderBoard.wins);
    await firestore.doc('Leaderboards/wins-all').set({
      'entries': [
        {'username': 'hal', 'photoUrl': '', 'value': 9},
      ],
    });
    await service.ensureLoaded(firestore, me, const []);
    expect(service.current!.entries.single.username, 'gus',
        reason: 'cached for the session');
    await service.ensureLoaded(firestore, me, const [], force: true);
    expect(service.current!.entries.single.username, 'hal');
  });

  test('logout forgets the boards and the choices', () async {
    service.setScope(LeaderScope.global);
    service.setBoard(LeaderBoard.wins);
    await service.ensureLoaded(firestore, me, const []);
    service.logout();
    expect(service.scope, LeaderScope.friends);
    expect(service.board, LeaderBoard.answers);
    expect(service.current, isNull);
  });
}
