import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/matchups.dart';
import '../../../data/prompt_day.dart';
import '../../../state/session_service.dart';
import '../../../state/voting_service.dart';

/// Settings > Hidden prompts: what the user hid from Home today, each with
/// Unhide. Prompts last a day, so the list empties at the rollover.
class HiddenPromptsPage extends StatefulWidget {
  const HiddenPromptsPage({super.key});

  @override
  State<HiddenPromptsPage> createState() => _HiddenPromptsPageState();
}

class _HiddenPromptsPageState extends State<HiddenPromptsPage> {
  final String _dayId = promptDayId(DateTime.now().toUtc());
  List<HiddenPrompt>? _prompts;
  bool _failed = false;

  FirebaseFirestore get _firestore =>
      Provider.of<FirebaseFirestore>(context, listen: false);
  String get _uid =>
      Provider.of<SessionService>(context, listen: false).loggedInUser?.uid ??
      '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prompts = await getHiddenPromptDetails(_firestore, _uid, _dayId);
      if (mounted) setState(() => _prompts = prompts);
    } catch (e) {
      debugPrint('hidden prompts: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _unhide(HiddenPrompt p) async {
    final voting = Provider.of<VotingService>(context, listen: false);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final before = _prompts!;
    final remaining = before.where((h) => h.promptId != p.promptId).toList();
    setState(() => _prompts = remaining);
    try {
      await saveHiddenPrompts(
          _firestore, _uid, _dayId, {for (final h in remaining) h.promptId});
      // Home's queue, if it's loaded, gets the prompt's matchups back
      voting.unhidePrompt(p.promptId, current: voting.current);
    } catch (e) {
      debugPrint('unhide: $e');
      if (mounted) setState(() => _prompts = before);
      messenger?.showSnackBar(
          const SnackBar(content: Text("Couldn't unhide it. Try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Hidden prompts',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    final prompts = _prompts;
    if (prompts == null) {
      return Center(
        child: _failed
            ? const Text("Couldn't load your hidden prompts",
                style: TextStyle(color: Colors.white70))
            : const CircularProgressIndicator(color: Colors.amber),
      );
    }
    if (prompts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "You haven't hidden any prompts today.\n"
            'Hold a prompt on Home to hide its matchups.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white70, fontFamily: 'OpenSans', fontSize: 16),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text("Their matchups stay off Home until today's prompts end.",
              style: TextStyle(color: Colors.white54, fontFamily: 'OpenSans')),
        ),
        for (final p in prompts)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: p.before),
                      const TextSpan(
                          text: '____', style: TextStyle(color: Colors.amber)),
                      TextSpan(text: p.after),
                    ]),
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontSize: 15),
                  ),
                ),
                TextButton(
                  onPressed: () => _unhide(p),
                  child: const Text('Unhide',
                      style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
