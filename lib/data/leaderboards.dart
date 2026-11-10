import 'package:cloud_firestore/cloud_firestore.dart';
import 'awards.dart';
import 'friends.dart';
import 'prompt_day.dart';
import 'prompt_stats.dart';

// The Leaderboard tab's data. Friends boards are worked out here from each
// friend's FriendView/profile and History (friends can read both), so they
// are always current. Global boards are the server's daily snapshot in
// Leaderboards/{board}, written by finishDay (functions/leaderboards.js).

enum LeaderScope {
  friends('Friends', 'You and your friends'),
  global('Global', 'Everyone on Chuckler');

  final String label;
  final String description;
  const LeaderScope(this.label, this.description);
}

enum LeaderBoard {
  answers('Top answers'),
  wins('Wins'),
  streak('Streak'),
  posts('Posts');

  final String label;
  const LeaderBoard(this.label);

  /// whether the board has a This week / All time toggle
  bool get hasPeriod => this == wins || this == posts;
}

enum LeaderPeriod {
  week('This week'),
  all('All time');

  final String label;
  const LeaderPeriod(this.label);
}

/// The Leaderboards doc id (and friends board key) for a board and period
String boardId(LeaderBoard board, LeaderPeriod period) => switch (board) {
      LeaderBoard.answers => 'answers',
      LeaderBoard.streak => 'streak',
      LeaderBoard.wins => 'wins-${period.name}',
      LeaderBoard.posts => 'posts-${period.name}',
    };

/// Every board id, friends boards are built all at once
const allBoardIds = [
  'answers',
  'streak',
  'wins-week',
  'wins-all',
  'posts-week',
  'posts-all',
];

/// One person on a ranked board
class LeaderEntry {
  final String username;
  final String photoUrl;
  final int value;
  final bool isMe;

  const LeaderEntry(this.username, this.photoUrl, this.value,
      {this.isMe = false});

  LeaderEntry asMe() => LeaderEntry(username, photoUrl, value, isMe: true);
}

/// One answer on the top answers board, with its author (shown only once
/// its day is over)
class TopAnswer {
  final String username;
  final String photoUrl;
  final String before;
  final String after;
  final String answer;
  final int wins;
  final int votes;
  final bool isMe;

  const TopAnswer(this.username, this.photoUrl, this.before, this.after,
      this.answer, this.wins, this.votes,
      {this.isMe = false});
}

/// A loaded board: ranked people, or answers for the top answers board
class Board {
  final List<LeaderEntry> entries;
  final List<TopAnswer> answers;

  /// the prompt day it stands for (top answers: the day that ended)
  final String? dayId;

  /// for weekly boards, the week's Monday
  final String? weekStart;

  const Board(
      {this.entries = const [],
      this.answers = const [],
      this.dayId,
      this.weekStart});

  bool get isEmpty => entries.isEmpty && answers.isEmpty;

  /// The user's row on this board, if they're on it
  LeaderEntry? get me {
    for (final e in entries) {
      if (e.isMe) return e;
    }
    return null;
  }
}

/// Places for values sorted best first, sharing a place on ties: 1, 2, 2, 4
List<int> ranks(List<int> values) {
  final out = <int>[];
  for (int i = 0; i < values.length; i++) {
    out.add(i > 0 && values[i] == values[i - 1] ? out[i - 1] : i + 1);
  }
  return out;
}

/// Best answers first: wins, then win rate, then votes (as the server does)
int compareTopAnswers(TopAnswer a, TopAnswer b) {
  double rate(TopAnswer t) => t.wins / (t.votes == 0 ? 1 : t.votes);
  final byWins = b.wins.compareTo(a.wins);
  if (byWins != 0) return byWins;
  final byRate = rate(b).compareTo(rate(a));
  if (byRate != 0) return byRate;
  return b.votes.compareTo(a.votes);
}

/// Friend prompt ids are {uid}_{dayId}; their answers stay off the boards,
/// so a friend prompt's audience stays private
bool isFriendPromptId(String promptId, String dayId) =>
    promptId.endsWith('_$dayId');

/// A global board from the server's snapshot. Entries whose username is
/// [myUsername] are marked as the user. An unwritten board is empty.
Future<Board> getGlobalBoard(FirebaseFirestore firestore, String id,
    {String? myUsername}) async {
  final doc = await firestore.collection('Leaderboards').doc(id).get();
  final data = doc.data();
  if (data == null) return const Board();
  final raw = (data['entries'] as List?) ?? const [];
  String str(Map m, String k) => (m[k] as String?) ?? '';
  int intOf(Map m, String k) => (m[k] as num?)?.toInt() ?? 0;
  if (id == 'answers') {
    return Board(dayId: data['dayId'] as String?, answers: [
      for (final e in raw.whereType<Map>())
        TopAnswer(
            str(e, 'username'),
            str(e, 'photoUrl'),
            str(e, 'before'),
            str(e, 'after'),
            str(e, 'answer'),
            intOf(e, 'wins'),
            intOf(e, 'votes'),
            isMe: myUsername != null && e['username'] == myUsername),
    ]);
  }
  return Board(
    dayId: data['dayId'] as String?,
    weekStart: data['weekStart'] as String?,
    entries: [
      for (final e in raw.whereType<Map>())
        LeaderEntry(str(e, 'username'), str(e, 'photoUrl'), intOf(e, 'value'),
            isMe: myUsername != null && e['username'] == myUsername),
    ],
  );
}

/// One person's numbers for the friends boards
class _Standing {
  final FriendCard who;
  final bool isMe;
  final Map<String, int> values;
  final List<TopAnswer> answers;

  _Standing(this.who, this.isMe, this.values, this.answers);
}

/// Reads one person's profile and the History month holding [yesterday]
Future<_Standing?> _standing(FirebaseFirestore firestore, FriendCard who,
    bool isMe, String today, String yesterday) async {
  try {
    final user = firestore.collection('Users').doc(who.uid);
    final docs = await Future.wait([
      user.collection('FriendView').doc('profile').get(),
      user.collection('History').doc(historyMonthId(yesterday)).get(),
    ]);
    final profile = docs[0].data() ?? const {};
    final week = profile['week'] as Map<String, dynamic>?;
    final thisWeek = week?['start'] == weekStartId(today);
    int weekly(String k) => thisWeek ? (week?[k] as num?)?.toInt() ?? 0 : 0;
    final values = {
      'wins-all': profileStat(profile, 'wins'),
      'posts-all': profileStat(profile, 'answers'),
      'wins-week': weekly('wins'),
      'posts-week': weekly('answers'),
      'streak': StreakRecord.fromMap(profile['streak'] as Map<String, dynamic>?)
          .currentAsOf(today),
    };
    final answers = <TopAnswer>[];
    final entries =
        (docs[1].data()?['answers'] as Map<String, dynamic>?) ?? const {};
    for (final raw in entries.values) {
      if (raw is! Map) continue;
      final promptId = (raw['promptId'] as String?) ?? '';
      final fin = raw['final'] as Map?;
      if (raw['promptDateId'] != yesterday ||
          fin == null ||
          isFriendPromptId(promptId, yesterday)) {
        continue;
      }
      final votes = (fin['votes'] as num?)?.toInt() ?? 0;
      if (votes == 0) continue;
      answers.add(TopAnswer(
          who.username,
          who.photoUrl,
          (raw['before'] as String?) ?? '',
          (raw['after'] as String?) ?? '',
          (raw['answer'] as String?) ?? '',
          (fin['wins'] as num?)?.toInt() ?? 0,
          votes,
          isMe: isMe));
    }
    return _Standing(who, isMe, values, answers);
  } catch (e) {
    return null; // unreadable (e.g. no longer friends): leave them out
  }
}

/// Every friends board at once, for the user ([me]) and their [friends].
/// Each person costs about four reads: their profile, a History month and
/// the rules' friend check on each. Top answers are yesterday's (the last
/// finished day); weekly counts from an older week read as zero.
Future<Map<String, Board>> getFriendBoards(
    FirebaseFirestore firestore, FriendCard me, List<FriendCard> friends,
    {DateTime? now}) async {
  final today = promptDayId((now ?? DateTime.now()).toUtc());
  final yesterday = addDays(today, -1);
  final people = await Future.wait([
    _standing(firestore, me, true, today, yesterday),
    for (final f in friends) _standing(firestore, f, false, today, yesterday),
  ]);
  final standings = people.whereType<_Standing>().toList();

  final boards = <String, Board>{};
  for (final id in allBoardIds.where((id) => id != 'answers')) {
    final rows = [
      for (final s in standings)
        LeaderEntry(s.who.username, s.who.photoUrl, s.values[id] ?? 0,
            isMe: s.isMe),
    ]..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        if (byValue != 0) return byValue;
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    boards[id] = Board(
        entries: rows,
        dayId: today,
        weekStart: id.endsWith('-week') ? weekStartId(today) : null);
  }
  boards['answers'] = Board(
      dayId: yesterday,
      answers: [for (final s in standings) ...s.answers]
        ..sort(compareTopAnswers));
  return boards;
}
