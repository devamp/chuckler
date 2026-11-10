import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../data/matchups.dart';
import '../createpage/create_stats.dart';
import '../friends/public_profile_page.dart';

/// One answer in a matchup. Its author shows only after the user votes. Swipe right to pick it as the winner, left to
/// downvote it. After the user votes it shows the results instead.
class VoteCard extends StatefulWidget {
  final MatchupAnswer answer;
  final Color accent;

  /// null until the user has voted on this matchup
  final MatchupVote? myVote;

  /// who wrote this answer; known only after the user votes
  final MatchupAuthor? author;
  final int card;
  final int pickPercent;
  final void Function(VoteType type) onVote;
  final VoidCallback onOpenComments;

  /// holding the card: report it, or block its author
  final VoidCallback? onHold;

  const VoteCard({
    super.key,
    required this.answer,
    required this.accent,
    required this.myVote,
    this.author,
    required this.card,
    required this.pickPercent,
    required this.onVote,
    required this.onOpenComments,
    this.onHold,
  });

  @override
  State<VoteCard> createState() => _VoteCardState();
}

class _VoteCardState extends State<VoteCard>
    with SingleTickerProviderStateMixin {
  double _dx = 0;
  late final AnimationController _settle;
  Animation<double>? _settleAnim;

  bool get _voted => widget.myVote != null;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        setState(() {
          _dx = _settleAnim!.value;
        });
      });
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_voted) return;
    _settle.stop();
    setState(() {
      _dx += d.delta.dx;
    });
  }

  void _onDragEnd(DragEndDetails d) {
    if (_voted) return;
    final width = context.size?.width ?? 300;
    final velocity = d.velocity.pixelsPerSecond.dx;
    if (_dx > width * 0.3 || velocity > 800) {
      widget.onVote(VoteType.win);
    } else if (_dx < -width * 0.3 || velocity < -800) {
      widget.onVote(VoteType.downvote);
    }
    //spring back to the middle either way
    _settleAnim = Tween<double>(begin: _dx, end: 0)
        .animate(CurvedAnimation(parent: _settle, curve: Curves.easeOut));
    _settle.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dragShare = (_dx.abs() / (width * 0.3)).clamp(0.0, 1.0);
    final picked = widget.myVote?.card == widget.card;

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onLongPress: widget.onHold,
      onTap: _voted ? widget.onOpenComments : null,
      child: Transform.translate(
        offset: Offset(_dx, 0),
        child: Transform.rotate(
          angle: _dx / width * 0.15,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: width / 30, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: picked ? widget.accent : Colors.black26,
                  width: picked ? 5 : 3),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // anonymous until the user votes. Answers carry no
                    // friends/global label, so a friend's answer looks like
                    // anyone else's; only prompts are categorized.
                    SizedBox(
                      height: 34,
                      child: _voted && widget.author != null
                          ? _authorTag(widget.author!)
                          : null,
                    ),
                    Expanded(
                      child: Center(
                        child: AutoSizeText(
                          widget.answer.answer,
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          minFontSize: 12,
                          style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'OpenSans',
                              fontSize: 26),
                        ),
                      ),
                    ),
                    _voted ? _results(picked) : _voteButtons(),
                  ],
                ),
                //label that fades in while dragging
                if (_dx != 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Opacity(
                          opacity: dragShare,
                          child: Text(
                            _dx > 0 ? 'WINNER' : 'DOWNVOTE',
                            style: TextStyle(
                                color: _dx > 0
                                    ? Colors.amberAccent
                                    : Colors.redAccent,
                                fontFamily: 'NewAmsterdam',
                                fontSize: 44),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The author's icon and name, at the top right
  /// Tap to open their profile, where you can send a friend request
  Widget _authorTag(MatchupAuthor author) {
    return Align(
      alignment: Alignment.centerRight,
      child: Semantics(
        button: true,
        label: "Open ${author.username}'s profile",
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PublicProfilePage(
                  username: author.username, photoUrl: author.photoUrl))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: _authorRow(author),
          ),
        ),
      ),
    );
  }

  Widget _authorRow(MatchupAuthor author) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            author.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: widget.accent,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        author.photoUrl.isNotEmpty
            ? CircleAvatar(
                radius: 13, backgroundImage: NetworkImage(author.photoUrl))
            : FriendAvatar(
                username: author.username,
                index: author.username.codeUnits.fold(0, (a, b) => a + b),
                radius: 13),
      ],
    );
  }

  Widget _voteButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Downvote this answer',
          onPressed: () => widget.onVote(VoteType.downvote),
          icon: const Icon(Icons.thumb_down_alt_outlined,
              color: Colors.redAccent),
        ),
        IconButton(
          tooltip: 'Pick this answer as the winner',
          onPressed: () => widget.onVote(VoteType.win),
          icon: const Icon(Icons.emoji_events_outlined,
              color: Colors.amberAccent),
        ),
      ],
    );
  }

  Widget _results(bool picked) {
    final downvoted = picked && widget.myVote!.type == VoteType.downvote;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.pickPercent}% picked this',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold),
              ),
            ),
            if (picked)
              Flexible(
                child: Text(
                  downvoted ? 'You downvoted' : 'Your pick',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: downvoted ? Colors.redAccent : Colors.amberAccent,
                      fontFamily: 'OpenSans'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: widget.pickPercent / 100,
            minHeight: 8,
            color: widget.accent,
            backgroundColor: Colors.white12,
          ),
        ),
      ],
    );
  }
}
