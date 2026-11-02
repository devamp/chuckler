import 'package:flutter/material.dart';
import '../../data/prompt_stats.dart';

/// Answers, votes and friends for a prompt, along the bottom of its card
class PromptStatsStrip extends StatelessWidget {
  /// null while loading
  final PromptStats? stats;

  const PromptStatsStrip({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final friends = s?.friendsAnswered ?? const [];
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 2))),
      child: Row(
        children: [
          Expanded(
              child: StatTile(
                  value: s == null ? '–' : compactCount(s.answers),
                  label: 'answers')),
          Expanded(
              child: StatTile(
                  value: s == null ? '–' : compactCount(s.votes),
                  label: 'votes')),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: friends.isEmpty
                  ? 'No friends have answered yet'
                  : '${friends.join(', ')} answered',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (int i = 0; i < friends.length && i < 3; i++)
                    Align(
                      widthFactor: 0.7,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.black87,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: _friendColors[i],
                          child: Text(friends[i][0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      friends.isEmpty
                          ? 'No friends yet'
                          : '${friends.length} '
                              '${friends.length == 1 ? 'friend' : 'friends'}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'OpenSans',
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const List<Color> _friendColors = [
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.lightBlueAccent,
];

/// A number with a small label under it
class StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatTile(
      {super.key,
      required this.value,
      required this.label,
      this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  color: color,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
        ),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white54, fontFamily: 'OpenSans', fontSize: 12)),
      ],
    );
  }
}

/// How the user's answer is doing, shown in place of the answer box once
/// they've answered
class YourAnswerPanel extends StatelessWidget {
  /// null while loading
  final AnswerStats? stats;

  /// answers to the prompt, for the "top x%" label
  final int answers;

  const YourAnswerPanel(
      {super.key, required this.stats, required this.answers});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final s = stats;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(width / 30, 0, width / 30, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('YOUR ANSWER',
                  style: TextStyle(
                      color: Colors.amberAccent,
                      fontFamily: 'NewAmsterdam',
                      fontSize: 22)),
              const Spacer(),
              if (s != null && s.rank > 0)
                Flexible(
                  child: Text(
                    '#${s.rank} of ${compactCount(answers)} · '
                    'Top ${s.topPercent(answers)}%',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (s == null)
            const Center(
                child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        color: Colors.amber, strokeWidth: 3)))
          else if (s.matchups == 0)
            const Text(
              'Waiting for its first matchup. Check back soon!',
              style: TextStyle(color: Colors.white70, fontFamily: 'OpenSans'),
            )
          else ...[
            Row(
              children: [
                Expanded(
                    child: StatTile(
                        value: compactCount(s.matchups), label: 'matchups')),
                Expanded(
                    child: StatTile(
                        value: compactCount(s.wins),
                        label: 'wins',
                        color: Colors.amberAccent)),
                Expanded(
                    child: StatTile(value: '${s.winRate}%', label: 'win rate')),
                Expanded(
                    child: StatTile(
                        value: compactCount(s.downvotes),
                        label: 'downvotes',
                        color: Colors.redAccent)),
              ],
            ),
            if (s.winsByHour.isNotEmpty) ...[
              const SizedBox(height: 10),
              WinsByHourBars(wins: s.winsByHour),
            ],
          ],
        ],
      ),
    );
  }
}

/// Small bar chart of wins per hour, oldest on the left
class WinsByHourBars extends StatelessWidget {
  final List<int> wins;

  const WinsByHourBars({super.key, required this.wins});

  @override
  Widget build(BuildContext context) {
    final most = wins.fold(1, (a, b) => b > a ? b : a);
    return Semantics(
      label: 'Wins per hour, last ${wins.length} hours: ${wins.join(', ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 34,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < wins.length; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 4 + 30 * wins[i] / most,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: i == wins.length - 1
                            ? Colors.amberAccent
                            : Colors.amberAccent.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text('Wins per hour, last ${wins.length} hours',
              style: const TextStyle(
                  color: Colors.white54, fontFamily: 'OpenSans', fontSize: 12)),
        ],
      ),
    );
  }
}

/// A one-line message in place of the answer box
class BottomNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const BottomNote({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(width / 30, 0, width / 30, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: Colors.amberAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'OpenSans')),
          ),
        ],
      ),
    );
  }
}
