import 'package:flutter/material.dart';
import '../data/matchups.dart';

/// Small label for a prompt's or matchup's segment
class SegmentChip extends StatelessWidget {
  final Segment segment;

  const SegmentChip({super.key, required this.segment});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (segment) {
      Segment.friends => ('Friends', Icons.people),
      Segment.local => ('Local', Icons.place),
      Segment.global => ('Global', Icons.public),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.black87, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.amberAccent),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'OpenSans', fontSize: 12)),
        ],
      ),
    );
  }
}
