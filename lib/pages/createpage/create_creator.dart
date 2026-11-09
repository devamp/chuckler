import 'package:flutter/material.dart';
import '../../CustomReusableWidgets/segment_chip.dart';
import '../../data/friend_prompts.dart';
import '../../data/matchups.dart';
import 'create_stats.dart';

/// A prompt creator's profile icon. The Chuckler account uses a placeholder
/// until its real icon is designed.
class CreatorAvatar extends StatelessWidget {
  final PromptCreator creator;
  final double radius;

  const CreatorAvatar({super.key, required this.creator, this.radius = 13});

  @override
  Widget build(BuildContext context) {
    if (creator.photoUrl.isNotEmpty) {
      return CircleAvatar(
          radius: radius, backgroundImage: NetworkImage(creator.photoUrl));
    }
    if (creator.kind != CreatorKind.user) {
      // TODO: swap in the Chuckler icon once it exists
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.amberAccent,
        child: Icon(Icons.sentiment_very_satisfied_rounded,
            color: Colors.black, size: radius * 1.5),
      );
    }
    return FriendAvatar(
        username: creator.username,
        index: creator.username.codeUnits.fold(0, (a, b) => a + b),
        radius: radius);
  }
}

/// The top of a prompt card: the creator's icon and name, with the prompt's
/// category under the name. Tap for the creator's profile.
class CreatorHeader extends StatelessWidget {
  final PromptCreator creator;
  final Segment segment;
  final bool isMe;

  const CreatorHeader(
      {super.key,
      required this.creator,
      required this.segment,
      this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = segmentLabel(segment);
    return Tooltip(
      message: "${isMe ? 'Your' : "${creator.username}'s"} profile",
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => showCreatorProfile(context, creator, isMe: isMe),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CreatorAvatar(creator: creator, radius: 19),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isMe ? 'You' : creator.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: Colors.amberAccent),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontFamily: 'OpenSans',
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The creator's public profile: icon, username, and a bio for official
/// accounts
void showCreatorProfile(BuildContext context, PromptCreator creator,
    {bool isMe = false}) {
  final (label, labelColor) = switch (creator.kind) {
    CreatorKind.official => ('Official account', Colors.amberAccent),
    CreatorKind.sponsor => ('Sponsored', Colors.lightBlueAccent),
    CreatorKind.user => (isMe ? 'You' : 'Friend', Colors.white70),
  };
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CreatorAvatar(creator: creator, radius: 40),
          const SizedBox(height: 12),
          Text(creator.username,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'NewAmsterdam',
                  fontSize: 32)),
          Text(label,
              style: TextStyle(color: labelColor, fontFamily: 'OpenSans')),
          const SizedBox(height: 16),
          if (creator.bio != null)
            Text(creator.bio!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontSize: 16))
          else if (!isMe)
            // TODO(cloud): open the friend's full profile (FriendView/profile,
            // History) once profiles can be opened from here.
            const Text("Their full profile will open here.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white54, fontFamily: 'OpenSans')),
        ],
      ),
    ),
  );
}
