import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/comments.dart';
import '../../data/matchups.dart';
import '../../state/session_service.dart';
import '../../state/moderation_service.dart';
import '../../data/moderation.dart';
import '../../CustomReusableWidgets/moderation_sheets.dart';
import '../createpage/create_stats.dart' show FriendAvatar;

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
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: _sheetColor,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => AnswerCommentsSheet(
        matchup: matchup, card: card, accent: accent, canComment: canComment),
  );
}

const Color _sheetColor = Color(0xFF1C1C1E);

/// "now", "5m", "3h", "2d", or a date
String commentAge(DateTime? at, DateTime now) {
  if (at == null) return 'now';
  final d = now.difference(at);
  if (d.inMinutes < 1) return 'now';
  if (d.inHours < 1) return '${d.inMinutes}m';
  if (d.inDays < 1) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${at.month}/${at.day}';
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
    // comments from people the user blocked, ones they reported and ones
    // with words they filter out stay hidden
    final moderation = Provider.of<ModerationService>(context);
    final comments = [
      for (final c in _thread?.comments ?? const <AnswerComment>[])
        if (!moderation.hidesComment(
            id: c.id, uid: c.uid, username: c.username, text: c.text))
          c,
    ];
    final media = MediaQuery.of(context);
    // about half the screen, so the matchup stays visible above it and a tap
    // there or a drag down closes it; the keyboard pushes it up
    final height = media.size.height * 0.5;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(comments.length),
            const Divider(height: 1, color: Colors.white10),
            Expanded(child: _body(comments)),
            if (widget.canComment) _composer() else _voteFirst(),
          ],
        ),
      ),
    );
  }

  Widget _header(int count) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      _thread == null || count == 0
                          ? 'Comments'
                          : 'Comments · $count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('"${_answer.answer}"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: widget.accent,
                          fontFamily: 'OpenSans',
                          fontSize: 14)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08)),
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 20),
            ),
          ],
        ),
      );

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.white24, size: 36),
            const SizedBox(height: 10),
            Text(
                widget.canComment
                    ? 'No comments yet. Start the conversation.'
                    : 'No comments yet',
                style: _muted),
          ],
        ),
      );
    }
    final now = DateTime.now();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      itemCount: comments.length,
      itemBuilder: (context, i) {
        final c = comments[i];
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => _openCommentMenu(c),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FriendAvatar(
                    username: c.username,
                    index: c.username.codeUnits.fold(0, (a, b) => a + b),
                    radius: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(c.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'OpenSans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                          const SizedBox(width: 6),
                          Text(commentAge(c.at, now),
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontFamily: 'OpenSans',
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(c.text,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'OpenSans',
                              fontSize: 15,
                              height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Holding someone else's comment: report it or block them
  Future<void> _openCommentMenu(AnswerComment c) async {
    final me =
        Provider.of<SessionService>(context, listen: false).loggedInUser?.uid;
    if (c.uid == me) return;
    await showHoldMenu(context, header: quoteHeader(c.text), actions: [
      HoldAction(
          icon: Icons.flag_outlined,
          label: 'Report comment',
          run: () => reportFlow(context,
              what: 'comment',
              target: ReportTarget.comment,
              targetId: c.id,
              postId: _thread?.postId,
              matchupId: widget.matchup.id)),
      HoldAction(
          icon: Icons.block,
          label: 'Block ${c.username}',
          danger: true,
          run: () => blockFlow(context, username: c.username, uid: c.uid)),
    ]);
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              maxLength: maxCommentLength,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Add a comment…',
                hintStyle: _muted,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Post comment',
            onPressed: _posting || _text.text.trim().isEmpty ? null : _post,
            style: IconButton.styleFrom(
              backgroundColor: widget.accent,
              disabledBackgroundColor: Colors.white12,
            ),
            icon: Icon(Icons.arrow_upward_rounded,
                color:
                    _text.text.trim().isEmpty ? Colors.white38 : Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _voteFirst() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white10))),
        child: const Text('Vote on this matchup to join the conversation',
            textAlign: TextAlign.center, style: _muted),
      );

  static const TextStyle _muted =
      TextStyle(color: Colors.white54, fontFamily: 'OpenSans');
}
