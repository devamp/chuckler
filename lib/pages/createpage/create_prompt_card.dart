import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../CustomReusableWidgets/segment_chip.dart';
import '../../data/prompt_stats.dart';
import '../../data/prompts.dart';
import '../../data/sample_prompts.dart';
import '../../database/models.dart';
import 'create_stats.dart';

/// Color of the user's own words inside a prompt
const Color answerColor = Color(0xfffbd0bf);

/// One prompt on the Create tab. The blank fills in with the user's draft or
/// answer, and a strip at the bottom shows how the prompt is doing.
class PromptCard extends StatelessWidget {
  final DbPrompt prompt;

  /// the posted answer, or the unsent draft ('' for none)
  final String answer;
  final bool answered;

  /// null while loading
  final PromptStats? stats;
  final DateTime now;

  final int likes;
  final bool liked;
  final VoidCallback onLike;

  /// drops the stats strip, for when the keyboard is up
  final bool compact;

  const PromptCard({
    super.key,
    required this.prompt,
    required this.answer,
    required this.answered,
    required this.stats,
    required this.now,
    required this.likes,
    required this.liked,
    required this.onLike,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final awaiting = isAwaitingPrompt(prompt);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: width / 30, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: answered ? Colors.amberAccent : Colors.black26,
            width: answered ? 4 : 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!awaiting)
            Row(
              children: [
                SegmentChip(segment: segmentOf(prompt)),
                if (isSamplePrompt(prompt)) ...[
                  const SizedBox(width: 6),
                  const Flexible(
                      child: _Tag(text: 'Sample', color: Colors.white54)),
                ],
                const Spacer(),
                Flexible(
                  flex: 3,
                  child: answered
                      ? const _Tag(
                          text: 'Answered',
                          color: Colors.amberAccent,
                          icon: Icons.check_circle)
                      : _Tag(
                          text: timeLeftLabel(now),
                          color: Colors.white70,
                          icon: Icons.timer_outlined),
                ),
              ],
            ),
          Expanded(
            child: Center(
              child: AutoSizeText.rich(
                TextSpan(
                  style: const TextStyle(
                      fontSize: 30, color: Colors.white, fontFamily: 'OpenSans'),
                  children: [
                    TextSpan(text: prompt.before),
                    answer.trim().isEmpty
                        ? const TextSpan(
                            text: '____________',
                            style: TextStyle(color: Colors.amber))
                        : TextSpan(
                            text: answer,
                            style: const TextStyle(color: answerColor)),
                    TextSpan(text: prompt.after),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 8,
                minFontSize: 10,
              ),
            ),
          ),
          if (!compact && !awaiting)
            PromptStatsStrip(
              stats: stats,
              likes: likes,
              liked: liked,
              onLike: onLike,
              onFriends: () =>
                  showFriendsAnswered(context, stats?.friendsAnswered ?? []),
            ),
        ],
      ),
    );
  }
}

/// Time until the prompt closes, e.g. "5h 12m left"
String timeLeftLabel(DateTime nowUtc) {
  // TODO(cloud): prompts close at the next UTC midnight for now. Once
  // prompts have lifetimes (TODO.md section 4), read the end time from
  // PromptDays/{promptDateId}/Prompts/{promptId}.endsAt instead.
  final end = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
      .add(const Duration(days: 1));
  final left = end.difference(nowUtc);
  if (left.inHours >= 1) {
    return '${left.inHours}h ${left.inMinutes % 60}m left';
  }
  return '${left.inMinutes.clamp(1, 59)}m left';
}

/// Small pill used in the card's top row
class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _Tag({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.black87, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontFamily: 'OpenSans', fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// One dot per prompt: the current one is a wide amber pill, answered ones
/// are filled in
class PageDots extends StatelessWidget {
  final int count;
  final int current;
  final List<bool> answered;

  const PageDots(
      {super.key,
      required this.count,
      required this.current,
      required this.answered});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == current ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == current
                    ? Colors.amberAccent
                    : answered[i]
                        ? Colors.amberAccent.withValues(alpha: 0.5)
                        : Colors.white24,
              ),
            ),
        ],
      ),
    );
  }
}

/// Answer streak in the header. Tap for the streak calendar.
class StreakChip extends StatelessWidget {
  final int days;
  final VoidCallback onTap;

  const StreakChip({super.key, required this.days, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$days days in a row answering a prompt',
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department,
                    color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 4),
                Text('$days day streak',
                    style: const TextStyle(
                        color: Colors.white,
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
