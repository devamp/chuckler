import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../data/friend_prompts.dart';

/// Opens the prompt builder. Returns the text before and after the blank,
/// already tidied, or null if the user backs out.
Future<(String, String)?> showPromptBuilder(BuildContext context) {
  return showModalBottomSheet<(String, String)>(
    context: context,
    backgroundColor: Colors.black87,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const PromptBuilder(),
  );
}

/// Write a fill-in-the-blank prompt for your friends: the text before the
/// blank, the text after it, and a live preview
class PromptBuilder extends StatefulWidget {
  const PromptBuilder({super.key});

  @override
  State<PromptBuilder> createState() => _PromptBuilderState();
}

class _PromptBuilderState extends State<PromptBuilder> {
  final TextEditingController _before = TextEditingController();
  final TextEditingController _after = TextEditingController();

  @override
  void dispose() {
    _before.dispose();
    _after.dispose();
    super.dispose();
  }

  bool get _ready =>
      _before.text.trim().isNotEmpty || _after.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final (before, after) = normalizePromptParts(_before.text, _after.text);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEW PROMPT',
                style: TextStyle(
                    color: Colors.amberAccent,
                    fontFamily: 'NewAmsterdam',
                    fontSize: 28)),
            const Text('Your friends fill in the blank.',
                style: TextStyle(color: Colors.white70, fontFamily: 'OpenSans')),
            const SizedBox(height: 14),
            // live preview
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 90),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 3),
              ),
              alignment: Alignment.center,
              child: AutoSizeText.rich(
                TextSpan(
                  style: const TextStyle(
                      fontSize: 22, color: Colors.white, fontFamily: 'OpenSans'),
                  children: [
                    TextSpan(text: before),
                    const TextSpan(
                        text: '________', style: TextStyle(color: Colors.amber)),
                    TextSpan(text: after),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 5,
                minFontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            field(_before, 'Before the blank', 'The worst thing to hear at a wedding is'),
            const SizedBox(height: 8),
            field(_after, 'After the blank (optional)', '!'),
            const SizedBox(height: 6),
            const Text('One new prompt a day.',
                style: TextStyle(
                    color: Colors.white54, fontFamily: 'OpenSans', fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _ready
                    ? () => Navigator.of(context)
                        .pop((_before.text, _after.text))
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Send to friends',
                    style: TextStyle(
                        color: _ready ? Colors.black : Colors.white38,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      maxLength: maxPromptPartLength,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: Colors.amberAccent,
      style: const TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        counterStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.amberAccent, width: 2)),
      ),
    );
  }
}
