import 'package:flutter/material.dart';
import 'create_prompt_card.dart';

/// Text field and Post button under the prompt cards
class AnswerBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool posting;
  final ValueChanged<String> onChanged;
  final VoidCallback onPost;

  const AnswerBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.posting,
    required this.onChanged,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(width / 30, 0, width / 30, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onTapOutside: (_) => focusNode.unfocus(),
              maxLines: 3,
              minLines: 1,
              maxLength: 500,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: Colors.amberAccent,
              style: const TextStyle(
                  color: answerColor, fontSize: 18, fontFamily: 'OpenSans'),
              decoration: InputDecoration(
                hintText: 'Your answer...',
                hintStyle: const TextStyle(color: Colors.white38),
                counterText: '',
                filled: true,
                fillColor: Colors.black54,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(color: Colors.amberAccent, width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final canPost = !posting && value.text.trim().isNotEmpty;
              return SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canPost ? onPost : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: posting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 3))
                      : Text('Post',
                          style: TextStyle(
                              color: canPost ? Colors.black : Colors.white38,
                              fontFamily: 'OpenSans',
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
