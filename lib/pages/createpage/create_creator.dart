import 'package:flutter/material.dart';
import '../../data/friend_prompts.dart';
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

/// The creator's icon and name at the top of a prompt card. Tap for their
/// profile.
class CreatorChip extends StatelessWidget {
  final PromptCreator creator;
  final bool isMe;

  const CreatorChip({super.key, required this.creator, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: "${isMe ? 'Your' : "${creator.username}'s"} profile",
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => showCreatorProfile(context, creator, isMe: isMe),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CreatorAvatar(creator: creator, radius: 13),
            const SizedBox(width: 6),
            Flexible(
              child: Text(isMe ? 'You' : creator.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
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
