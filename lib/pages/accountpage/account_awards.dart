import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/awards.dart';
import '../../state/account_service.dart';

const Color _gold = Color(0xFFffd230);

/// Each track's icon. Tracks the app doesn't know yet (added to
/// functions/awards.json after this build) get the default.
const Map<String, FaIconData> awardIcons = {
  'posts': FontAwesomeIcons.solidNoteSticky,
  'streak': FontAwesomeIcons.fire,
  'friends': FontAwesomeIcons.userGroup,
  'comments': FontAwesomeIcons.comment,
  'wins': FontAwesomeIcons.medal,
  'leaderboard': FontAwesomeIcons.trophy,
  'top1': FontAwesomeIcons.percent,
  'referral': FontAwesomeIcons.handshakeAngle,
};
const FaIconData defaultAwardIcon = FontAwesomeIcons.award;

String _date(DateTime? d) {
  if (d == null) return 'Earned';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final l = d.toLocal();
  return 'Earned ${months[l.month - 1]} ${l.day}, ${l.year}';
}

/// The Account tab's Achievements: one badge per award track from the
/// catalog. Earned badges are gold; the next tier shows progress; awards
/// that can't be tracked yet are locked as "Coming soon".
class AwardsPage extends StatelessWidget {
  const AwardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final account = Provider.of<AccountService>(context);
    final awards = account.awards;
    if (!account.loaded) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    final earned = awards.fold<int>(0, (t, a) => t + a.earnedTiers.length);
    final total = awards
        .where((a) => !a.comingSoon)
        .fold<int>(0, (t, a) => t + a.track.tiers.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Text('$earned of $total earned',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            const columns = 3;
            const gap = 12.0;
            final width =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: 18,
              children: [
                for (final a in awards)
                  SizedBox(width: width, child: AwardBadge(progress: a)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// One award track: icon, tier name, tier dots and progress. Tap for every
/// tier and when it was earned.
class AwardBadge extends StatelessWidget {
  final AwardProgress progress;

  const AwardBadge({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final hasEarned = p.latest != null;
    final color = p.comingSoon
        ? Colors.white30
        : hasEarned
            ? _gold
            : Colors.white;
    final name =
        p.comingSoon ? p.track.tiers.first.name : (p.latest ?? p.shown).name;
    final next = p.next;

    // Every badge has the same fixed slots (icon, two-line name, tier dots,
    // progress), so badges in a row line up whatever they show.
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showDetails(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  FaIcon(awardIcons[p.track.id] ?? defaultAwardIcon,
                      size: 34, color: color),
                  if (p.comingSoon)
                    const Positioned(
                      right: -4,
                      bottom: -2,
                      child: Icon(Icons.lock, size: 16, color: Colors.white54),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: Center(
                child: Text(name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: p.comingSoon ? Colors.white54 : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.2)),
              ),
            ),
            SizedBox(
              height: 11,
              child: !p.comingSoon && p.track.tiers.length > 1
                  ? _tierDots()
                  : null,
            ),
            SizedBox(
              height: 26,
              child: p.comingSoon
                  ? const Center(
                      child: Text('Coming soon',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)))
                  : next != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: p.fraction,
                                minHeight: 5,
                                color: _gold,
                                backgroundColor: Colors.white12,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text('${p.value} / ${next.at}',
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                    height: 1.1)),
                          ],
                        )
                      : const Center(
                          child: Text('Complete',
                              style: TextStyle(color: _gold, fontSize: 12))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tierDots() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final t in progress.track.tiers)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: progress.isEarned(t) ? _gold : Colors.white24,
              ),
            ),
        ],
      );

  void _showDetails(BuildContext context) {
    final p = progress;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
        title: Column(
          children: [
            FaIcon(awardIcons[p.track.id] ?? defaultAwardIcon,
                size: 32,
                color: p.comingSoon
                    ? Colors.white38
                    : p.latest != null
                        ? _gold
                        : Colors.white),
            const SizedBox(height: 12),
            Text((p.latest ?? p.shown).name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _gold, fontSize: 24)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (p.comingSoon) ...[
              Text(p.track.tiers.first.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10),
              const Text("Coming soon: this award can't be earned yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ] else
              for (final t in p.track.tiers) _tierRow(t),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, backgroundColor: _gold),
              child: const Text('Ok'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierRow(AwardTier t) {
    final p = progress;
    final done = p.isEarned(t);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? _gold : Colors.white38, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(t.description,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                Text(
                    done
                        ? _date(p.earned[t.at])
                        : '${p.value.clamp(0, t.at ?? 0)} / ${t.at}',
                    style: TextStyle(
                        color: done ? _gold : Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
