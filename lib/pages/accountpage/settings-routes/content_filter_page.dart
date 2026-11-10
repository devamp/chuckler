import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/moderation_service.dart';
import '../../../state/session_service.dart';

/// Settings > Content filter: which kinds of language to hide. Answers,
/// comments and prompts that may contain words from a switched-on category
/// are hidden for this user only; nobody is stopped from posting them.
class ContentFilterPage extends StatelessWidget {
  const ContentFilterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final moderation = Provider.of<ModerationService>(context);
    final on = moderation.contentFilter;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Content filter',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
                'Hide answers, comments and prompts that may contain these. '
                'Only you are affected.',
                style:
                    TextStyle(color: Colors.white54, fontFamily: 'OpenSans')),
          ),
          Material(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < moderation.categories.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, indent: 16, color: Colors.white12),
                  SwitchListTile(
                    value: on.contains(moderation.categories[i].id),
                    activeThumbColor: Colors.amberAccent,
                    title: Text(moderation.categories[i].label,
                        style: const TextStyle(
                            color: Colors.white, fontFamily: 'OpenSans')),
                    onChanged: (value) => moderation
                        .setFiltered(
                            Provider.of<FirebaseFirestore>(context,
                                listen: false),
                            Provider.of<SessionService>(context, listen: false)
                                    .loggedInUser
                                    ?.uid ??
                                '',
                            moderation.categories[i].id,
                            value)
                        .catchError((Object e) {
                      debugPrint('content filter: $e');
                    }),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
