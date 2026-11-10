import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/moderation_service.dart';
import '../../../state/session_service.dart';
import '../../createpage/create_stats.dart' show FriendAvatar;

/// Settings > Blocked users: everyone the user blocked, each with Unblock.
/// Unblocking doesn't make them friends again.
class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final moderation = Provider.of<ModerationService>(context);
    final blocked = moderation.blocked;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Blocked users',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: blocked.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "You haven't blocked anyone.\nHold someone's answer, "
                  'comment, prompt or profile to block them.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white70,
                      fontFamily: 'OpenSans',
                      fontSize: 16),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Text(
                      "They can't send you friend requests, and you won't see "
                      'their answers, comments or prompts. They aren\'t told.',
                      style: TextStyle(
                          color: Colors.white54, fontFamily: 'OpenSans')),
                ),
                for (final b in blocked)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        FriendAvatar(
                            username: b.username,
                            index:
                                b.username.codeUnits.fold(0, (a, c) => a + c),
                            radius: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(b.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'OpenSans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ),
                        TextButton(
                          onPressed: () => _unblock(context, b.uid, b.username),
                          child: const Text('Unblock',
                              style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _unblock(BuildContext context, String uid, String name) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await Provider.of<ModerationService>(context, listen: false).unblock(
          Provider.of<FirebaseFirestore>(context, listen: false),
          Provider.of<SessionService>(context, listen: false)
                  .loggedInUser
                  ?.uid ??
              '',
          uid);
      messenger?.showSnackBar(SnackBar(content: Text('Unblocked $name')));
    } catch (e) {
      debugPrint('unblock: $e');
      messenger?.showSnackBar(
          const SnackBar(content: Text("Couldn't unblock them. Try again.")));
    }
  }
}
