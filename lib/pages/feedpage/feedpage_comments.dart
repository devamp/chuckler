import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/comments.dart';
import '../../data/matchups.dart';
import '../../state/session_service.dart';

/// Opens the comment thread of one answer. Threads belong to the answer, not
/// the matchup, so they follow it as matchups change. Only voters may add to
/// it, so the text field shows once the user has voted on this matchup.
void showAnswerComments(BuildContext context,
    {required Matchup matchup,
    required int card,
    required Color accent,
    required bool canComment}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => AnswerCommentsSheet(
        matchup: matchup, card: card, accent: accent, canComment: canComment),
  );
}

class AnswerCommentsSheet extends StatefulWidget {
  final Matchup matchup;
  final int card;
  final Color accent;
  final bool canComment;

  const AnswerCommentsSheet(
      {super.key,
      required this.matchup,
      required this.card,
      required this.accent,
      required this.canComment});

  @override
  State<AnswerCommentsSheet> createState() => _AnswerCommentsSheetState();
}

class _AnswerCommentsSheetState extends State<AnswerCommentsSheet> {
  CommentThread? _thread;
  String? _error;
  bool _posting = false;
  final TextEditingController _text = TextEditingController();

  MatchupAnswer get _answer => widget.matchup.answers[widget.card];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final thread = await getCommentThread(
          Provider.of<FirebaseFirestore>(context, listen: false),
          _answer.postId);
      if (mounted) setState(() => _thread = thread);
    } catch (e) {
      debugPrint('comments: $e');
      if (mounted) setState(() => _error = "Couldn't load comments");
    }
  }

  Future<void> _post() async {
    final thread = _thread;
    final user =
        Provider.of<SessionService>(context, listen: false).loggedInUser;
    if (thread == null || user == null || _text.text.trim().isEmpty) return;
    setState(() => _posting = true);
    try {
      final c = await addComment(
          Provider.of<FirebaseFirestore>(context, listen: false),
          user,
          thread,
          widget.matchup.id,
          _text.text);
      _text.clear();
      if (!mounted) return;
      setState(() {
        final pageFull = thread.lastPageSize >= commentsPerPage;
        _thread = CommentThread(
            thread.postId,
            [...thread.comments, c],
            thread.pages == 0 || pageFull ? thread.pages + 1 : thread.pages,
            thread.pages == 0 || pageFull ? 1 : thread.lastPageSize + 1);
      });
    } catch (e) {
      debugPrint('comment refused: $e');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text("Your comment didn't go through")));
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = _thread?.comments ?? const <AnswerComment>[];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"${_answer.answer}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: widget.accent,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 8),
              Expanded(child: _body(comments)),
              if (widget.canComment) _composer() else _voteFirst(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(List<AnswerComment> comments) {
    if (_error != null) {
      return Center(child: Text(_error!, style: _muted));
    }
    if (_thread == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.amber));
    }
    if (comments.isEmpty) {
      return Center(
          child: Text(
              widget.canComment ? 'No comments yet. Say something!' : 'No comments yet',
              style: _muted));
    }
    return ListView.builder(
      itemCount: comments.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '${comments[i].username}  ',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: comments[i].text),
          ]),
          style: const TextStyle(
              color: Colors.white, fontFamily: 'OpenSans', fontSize: 15),
        ),
      ),
    );
  }

  Widget _composer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            maxLength: maxCommentLength,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Add a comment',
              hintStyle: _muted,
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Post comment',
          onPressed: _posting ? null : _post,
          icon: Icon(Icons.send, color: widget.accent),
        ),
      ],
    );
  }

  Widget _voteFirst() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Vote on this matchup to comment', style: _muted),
      );

  static const TextStyle _muted =
      TextStyle(color: Colors.white54, fontFamily: 'OpenSans');
}
