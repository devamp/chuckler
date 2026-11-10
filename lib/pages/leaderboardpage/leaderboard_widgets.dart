import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../data/leaderboards.dart';
import '../createpage/create_stats.dart';
import '../friends/public_profile_page.dart';

const _medals = [Color(0xFFFFD230), Color(0xFFC9D1D9), Color(0xFFD08B4E)];
const _card = Color(0xCC1C1C1E);

/// The medal color for a place, or null past third
Color? medalColor(int rank) => rank <= 3 ? _medals[rank - 1] : null;

/// "12 wins", "1 post", "5 days" for a board's values
String valueLabel(LeaderBoard board, int value) {
  final (one, many) = switch (board) {
    LeaderBoard.wins || LeaderBoard.answers => ('win', 'wins'),
    LeaderBoard.posts => ('post', 'posts'),
    LeaderBoard.streak => ('day', 'days'),
  };
  return '$value ${value == 1 ? one : many}';
}

/// A profile photo, or the initial in a colored circle without one
Widget leaderAvatar(String username, String photoUrl, double radius) {
  if (photoUrl.isNotEmpty) {
    return CircleAvatar(
        radius: radius, backgroundImage: NetworkImage(photoUrl));
  }
  return FriendAvatar(
      username: username,
      index: username.codeUnits.fold(0, (a, b) => a + b),
      radius: radius);
}

/// Opens someone's profile, where a stranger can be sent a friend request.
/// The user's own row does nothing.
void openLeaderProfile(
    BuildContext context, String username, String photoUrl, bool isMe) {
  if (isMe) return;
  Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          PublicProfilePage(username: username, photoUrl: photoUrl)));
}

/// The top three on a pedestal: second, first, third from left to right
class Podium extends StatelessWidget {
  final List<LeaderEntry> top;
  final List<int> places;
  final LeaderBoard board;

  const Podium(
      {super.key,
      required this.top,
      required this.places,
      required this.board});

  @override
  Widget build(BuildContext context) {
    Widget slot(int i, double height, double radius) {
      if (i >= top.length) return const Expanded(child: SizedBox());
      return Expanded(
          child: _PodiumSlot(
              entry: top[i],
              place: places[i],
              board: board,
              height: height,
              radius: radius));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [slot(1, 62, 26), slot(0, 88, 34), slot(2, 46, 26)],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final LeaderEntry entry;
  final int place;
  final LeaderBoard board;
  final double height;
  final double radius;

  const _PodiumSlot(
      {required this.entry,
      required this.place,
      required this.board,
      required this.height,
      required this.radius});

  @override
  Widget build(BuildContext context) {
    final color = medalColor(place) ?? Colors.white24;
    return Semantics(
      button: !entry.isMe,
      label: 'Place $place, ${entry.username}, '
          '${valueLabel(board, entry.value)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openLeaderProfile(
            context, entry.username, entry.photoUrl, entry.isMe),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (place == 1)
              const Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFFFD230), size: 26),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3)),
              child: leaderAvatar(entry.username, entry.photoUrl, radius),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(entry.isMe ? 'You' : entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: entry.isMe ? Colors.amberAccent : Colors.white,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
            Text(valueLabel(board, entry.value),
                style: const TextStyle(
                    color: Colors.white70,
                    fontFamily: 'OpenSans',
                    fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.55),
                      color.withValues(alpha: 0.12)
                    ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              alignment: Alignment.center,
              child: Text('$place',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'NewAmsterdam',
                      fontSize: 30)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One ranked person below the podium. The user's row is highlighted;
/// [note] replaces the place for a row pinned off the list.
class LeaderRow extends StatelessWidget {
  final LeaderEntry entry;
  final int? place;
  final LeaderBoard board;
  final String? note;

  /// false for the pinned row, whose global value isn't known
  final bool showValue;

  const LeaderRow(
      {super.key,
      required this.entry,
      required this.place,
      required this.board,
      this.note,
      this.showValue = true});

  @override
  Widget build(BuildContext context) {
    final me = entry.isMe;
    final text = me ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Material(
        color: me ? Colors.amberAccent : _card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openLeaderProfile(
              context, entry.username, entry.photoUrl, entry.isMe),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(place == null ? '–' : '$place',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: text,
                          fontFamily: 'NewAmsterdam',
                          fontSize: 22)),
                ),
                const SizedBox(width: 8),
                leaderAvatar(entry.username, entry.photoUrl, 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(me ? '${entry.username} (you)' : entry.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: text,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      if (note != null)
                        Text(note!,
                            style: TextStyle(
                                color: text.withValues(alpha: 0.7),
                                fontFamily: 'OpenSans',
                                fontSize: 12)),
                    ],
                  ),
                ),
                if (showValue)
                  Text(valueLabel(board, entry.value),
                      style: TextStyle(
                          color: text,
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One answer on the top answers board: its place, the prompt, the answer
/// and who wrote it
class TopAnswerCard extends StatelessWidget {
  final TopAnswer answer;
  final int place;

  const TopAnswerCard({super.key, required this.answer, required this.place});

  @override
  Widget build(BuildContext context) {
    final medal = medalColor(place);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: answer.isMe
                ? Colors.amberAccent
                : (medal ?? Colors.white12).withValues(alpha: 0.7),
            width: answer.isMe || medal != null ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: medal ?? Colors.white12, shape: BoxShape.circle),
                child: Text('$place',
                    style: TextStyle(
                        color: medal == null ? Colors.white : Colors.black,
                        fontFamily: 'NewAmsterdam',
                        fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: answer.before),
                    const TextSpan(
                        text: '____', style: TextStyle(color: Colors.amber)),
                    TextSpan(text: answer.after),
                  ]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white60,
                      fontFamily: 'OpenSans',
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AutoSizeText(answer.answer,
              maxLines: 3,
              minFontSize: 13,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 19)),
          const SizedBox(height: 10),
          Row(
            children: [
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => openLeaderProfile(
                      context, answer.username, answer.photoUrl, answer.isMe),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        leaderAvatar(answer.username, answer.photoUrl, 12),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(answer.isMe ? 'You' : answer.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: answer.isMe
                                      ? Colors.amberAccent
                                      : Colors.white,
                                  fontFamily: 'OpenSans',
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.emoji_events_outlined,
                  color: Colors.amberAccent, size: 16),
              const SizedBox(width: 4),
              Text('${answer.wins} of ${answer.votes}',
                  style: const TextStyle(
                      color: Colors.white70, fontFamily: 'OpenSans')),
            ],
          ),
        ],
      ),
    );
  }
}
