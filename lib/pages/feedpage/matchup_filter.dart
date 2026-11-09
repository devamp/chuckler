import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/matchups.dart';
import '../../state/voting_service.dart';

IconData _iconFor(MatchupFilter f) => switch (f) {
      MatchupFilter.all => Icons.all_inclusive,
      MatchupFilter.global => Icons.public,
      MatchupFilter.friends => Icons.people_alt,
    };

/// The Home tab's filter: a pill showing the current choice that opens a
/// menu of All, Global and Friends, each with how many matchups it has.
class MatchupFilterButton extends StatelessWidget {
  const MatchupFilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final voting = Provider.of<VotingService>(context);
    final current = voting.filter;
    return PopupMenuButton<MatchupFilter>(
      tooltip: 'Filter matchups',
      initialValue: current,
      onSelected: voting.setFilter,
      offset: const Offset(0, 48),
      color: const Color(0xFF1C1C1E),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      itemBuilder: (context) => [
        for (final f in MatchupFilter.values)
          PopupMenuItem<MatchupFilter>(
            value: f,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: _menuRow(
                f, f == current, voting.loaded ? voting.countFor(f) : null),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(current), color: Colors.amberAccent, size: 18),
            const SizedBox(width: 8),
            Text(current.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white70, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _menuRow(MatchupFilter f, bool selected, int? count) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? Colors.amberAccent
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconFor(f),
                size: 18, color: selected ? Colors.black : Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(f.label,
                    style: TextStyle(
                        color: selected ? Colors.amberAccent : Colors.white,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(f.description,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'OpenSans',
                        fontSize: 12)),
              ],
            ),
          ),
          if (count != null)
            Text('$count',
                style: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
