import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/matchups.dart';
import '../../data/prompt_day.dart';
import '../../data/moderation.dart';
import '../../CustomReusableWidgets/moderation_sheets.dart';
import '../../state/moderation_service.dart';
import '../../state/prompt_service.dart';
import '../../state/session_service.dart';
import '../../state/voting_service.dart';
import 'feedpage_comments.dart';
import 'feedpage_vote_card.dart';

const String voteTutorialSeenKey = 'voteTutorialSeen';

/// Swipe voting: two stacked answers to the same prompt. Swipe right on the
/// winner, left to downvote, up to skip or move on, down to go back.
class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage>
    with SingleTickerProviderStateMixin {
  final List<Color> answerColors = [Colors.greenAccent, Colors.purpleAccent];
  bool _showTutorial = false;

  /// How far the page has moved up (negative) or down while swiping, in
  /// pixels. The neighbouring matchup follows it in from below or above.
  double _offset = 0;
  double _travel = 0;
  late final AnimationController _slide;
  Animation<double>? _slideAnim;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280))
      ..addListener(() => setState(() => _offset = _slideAnim!.value));
    // keep reported, blocked and filtered matchups out of the queue
    _moderation = Provider.of<ModerationService>(context, listen: false);
    _voting = Provider.of<VotingService>(context, listen: false);
    _voting.exclude = (m) => _moderation.hidesMatchup(
        id: m.id,
        prompt: '${m.promptBefore} ${m.promptAfter}',
        answers: m.answers.map((a) => a.answer));
    _moderation.addListener(_voting.refilter);
    loadMatchups();
    checkTutorial();
  }

  late final ModerationService _moderation;
  late final VotingService _voting;

  @override
  void dispose() {
    _moderation.removeListener(_voting.refilter);
    _slide.dispose();
    super.dispose();
  }

  /// Slides the page to [to], then runs [then] (moving the queue) and puts
  /// the page back at rest, where the neighbour it slid in now sits.
  /// With [stay], the page stays at [to] (the refresh hold) instead.
  Future<void> _slideTo(double to,
      {VoidCallback? then, bool stay = false}) async {
    _slideAnim = Tween<double>(begin: _offset, end: to)
        .animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic));
    await _slide.forward(from: 0);
    if (!mounted) return;
    then?.call();
    if (!stay) setState(() => _offset = 0);
  }

  void _goNext() {
    final voting = Provider.of<VotingService>(context, listen: false);
    if (!voting.canGoNext || _slide.isAnimating) return;
    _slideTo(-_travel, then: voting.next);
  }

  void _goBack() {
    final voting = Provider.of<VotingService>(context, listen: false);
    if (!voting.canGoBack || _slide.isAnimating) return;
    _slideTo(_travel, then: voting.back);
  }

  /// How far (after the drag is damped) a pull down with nothing to go
  /// back to must reach to refresh, and where the page waits meanwhile
  static const double refreshPull = 70;
  static const double _refreshHold = 56;
  bool _refreshing = false;

  /// A pull down with no matchup behind this one: it refreshes instead
  bool _pullsToRefresh(VotingService voting) =>
      _offset > 0 && !voting.canGoBack;

  void _onDragUpdate(DragUpdateDetails d, VotingService voting) {
    if (_slide.isAnimating || _refreshing) return;
    final next = _offset + d.delta.dy;
    // past the last matchup the page only gives a little; pulling down
    // from the first one gives more, to reach the refresh
    final double give = next < 0 && !voting.canGoNext
        ? 0.25
        : next > 0 && !voting.canGoBack
            ? 0.45
            : 1;
    setState(() => _offset += d.delta.dy * give);
  }

  /// Reloads today's matchups while the page waits a little way down
  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await _slideTo(_refreshHold, stay: true);
    try {
      await loadMatchups(force: true);
    } finally {
      if (mounted) {
        await _slideTo(0);
        if (mounted) setState(() => _refreshing = false);
      }
    }
  }

  void _onDragEnd(DragEndDetails d, VotingService voting) {
    if (_slide.isAnimating || _refreshing) return;
    final speed = d.velocity.pixelsPerSecond.dy;
    if (_pullsToRefresh(voting) && _offset >= refreshPull) {
      _refresh();
    } else if (voting.canGoNext &&
        (_offset < -80 || (_offset < -20 && speed < -600))) {
      _slideTo(-_travel, then: voting.next);
    } else if (voting.canGoBack &&
        (_offset > 80 || (_offset > 20 && speed > 600))) {
      _slideTo(_travel, then: voting.back);
    } else {
      _slideTo(0);
    }
  }

  /// Loads today's matchups once per session, or again when [force] is set
  /// (the "check for new ones" button).
  Future<void> loadMatchups({bool force = false}) async {
    VotingService votingService =
        Provider.of<VotingService>(context, listen: false);
    if (votingService.loaded && !force) {
      return;
    }
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    String uid =
        Provider.of<SessionService>(context, listen: false).loggedInUser?.uid ??
            '';
    final myPostIds = {
      for (final p in Provider.of<PromptService>(context, listen: false)
          .userPostsForPrompts)
        if ((p?.postId ?? '').isNotEmpty) p!.postId!,
    };
    List<Matchup> matchups = [];
    Set<String> hidden = {};
    try {
      final results = await Future.wait([
        getVotingMatchups(firestore, uid, myPostIds),
        getHiddenPrompts(firestore, uid, promptDayId(DateTime.now().toUtc()))
            .catchError((Object e) {
          debugPrint('hidden prompts: $e');
          return <String>{};
        }),
      ]);
      matchups = results[0] as List<Matchup>;
      hidden = results[1] as Set<String>;
    } catch (e) {
      debugPrint('matchups: $e');
    }
    votingService.setMatchups(matchups, myPostIds, hidden: hidden);
  }

  Future<void> checkTutorial() async {
    bool seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(voteTutorialSeenKey) ?? false;
    } catch (e) {
      debugPrint("$e");
    }
    if (!seen && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  Future<void> dismissTutorial() async {
    setState(() {
      _showTutorial = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(voteTutorialSeenKey, true);
    } catch (e) {
      debugPrint("$e");
    }
  }

  Future<void> onVote(Matchup m, int card, VoteType type) async {
    VotingService votingService =
        Provider.of<VotingService>(context, listen: false);
    if (!votingService.vote(card, type)) {
      return;
    }
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    try {
      await castVote(
          firestore,
          Provider.of<SessionService>(context, listen: false)
                  .loggedInUser
                  ?.uid ??
              '',
          m,
          votingService.voteFor(m)!);
    } catch (e) {
      // refused (already voted elsewhere, or offline): take it back
      debugPrint('vote refused: $e');
      votingService.undoVote(m);
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text("Your vote didn't go through")));
      }
      return;
    }
    // the vote is saved, so the authors can be revealed
    final authors = await getMatchupAuthors(firestore, m.id);
    if (authors != null) votingService.setAuthors(m, authors);
  }

  /// The uid in a friend prompt's id ({uid}_{dayId}), or null for a daily
  /// prompt
  String? _friendPromptCreator(Matchup m) {
    if (m.scope != MatchupScope.friends) return null;
    final cut = m.promptId.lastIndexOf('_');
    return cut > 0 ? m.promptId.substring(0, cut) : null;
  }

  /// Holding the prompt: hide it from the queue, report it, or (a friend
  /// prompt) block whoever wrote it
  Future<void> openPromptMenu(Matchup m) async {
    final me =
        Provider.of<SessionService>(context, listen: false).loggedInUser?.uid;
    final creator = _friendPromptCreator(m);
    await showHoldMenu(context,
        header: promptHeader(m.promptBefore, m.promptAfter),
        actions: [
          HoldAction(
              icon: Icons.visibility_off_outlined,
              label: 'Hide this prompt',
              subtitle: "You won't see matchups for it today.",
              run: () async {
                if (mounted) await hidePrompt(m);
              }),
          HoldAction(
              icon: Icons.flag_outlined,
              label: 'Report prompt',
              run: () => reportFlow(context,
                  what: 'prompt',
                  target: ReportTarget.prompt,
                  targetId: m.promptId)),
          if (creator != null && creator != me)
            HoldAction(
                icon: Icons.block,
                label: 'Block whoever wrote it',
                danger: true,
                run: () async {
                  final firestore =
                      Provider.of<FirebaseFirestore>(context, listen: false);
                  final name = await usernameForUid(firestore, creator);
                  if (name == null || !mounted) return;
                  await blockFlow(context,
                      username: name, uid: creator, matchupId: m.id);
                }),
        ]);
  }

  /// Holding an answer: report it, or block its author once they're known
  /// (after voting)
  Future<void> openAnswerMenu(Matchup m, int card) async {
    final voting = Provider.of<VotingService>(context, listen: false);
    final me = Provider.of<SessionService>(context, listen: false)
        .loggedInUser
        ?.username;
    final author = voting.authorsFor(m)?[card];
    await showHoldMenu(context,
        header: quoteHeader(m.answers[card].answer),
        actions: [
          HoldAction(
              icon: Icons.flag_outlined,
              label: 'Report answer',
              subtitle: "It leaves your queue now.",
              run: () => reportFlow(context,
                  what: 'answer',
                  target: ReportTarget.answer,
                  targetId: m.answers[card].postId,
                  postId: m.answers[card].postId,
                  matchupId: m.id)),
          if (author != null && author.username != me)
            HoldAction(
                icon: Icons.block,
                label: 'Block ${author.username}',
                danger: true,
                run: () => blockFlow(context,
                    username: author.username,
                    photoUrl: author.photoUrl,
                    matchupId: m.id)),
        ]);
  }

  /// Hides [m]'s prompt from the queue, saves it, and offers Undo
  Future<void> hidePrompt(Matchup m) async {
    final voting = Provider.of<VotingService>(context, listen: false);
    final firestore = Provider.of<FirebaseFirestore>(context, listen: false);
    final uid =
        Provider.of<SessionService>(context, listen: false).loggedInUser?.uid ??
            '';
    final dayId = m.promptDateId.isNotEmpty
        ? m.promptDateId
        : promptDayId(DateTime.now().toUtc());
    Future<void> save() async {
      try {
        await saveHiddenPrompts(firestore, uid, dayId, voting.hiddenPrompts);
      } catch (e) {
        debugPrint('hide prompt: $e'); // stays hidden for this session
      }
    }

    voting.hidePrompt(m.promptId);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(
      content: const Text('Prompt hidden'),
      action: SnackBarAction(
        label: 'Undo',
        textColor: Colors.amberAccent,
        onPressed: () {
          voting.unhidePrompt(m.promptId, current: m);
          save();
        },
      ),
    ));
    await save();
  }

  /// Opens the comment thread of one answer
  void openComments(Matchup m, int card) {
    showAnswerComments(context,
        matchup: m,
        card: card,
        accent: answerColors[card],
        canComment:
            Provider.of<VotingService>(context, listen: false).hasVoted(m));
  }

  @override
  Widget build(BuildContext context) {
    VotingService votingService =
        Provider.of<VotingService>(context, listen: true);
    Matchup? m = votingService.current;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: !votingService.loaded
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber))
                  : LayoutBuilder(builder: (context, box) {
                      _travel = box.maxHeight;
                      return GestureDetector(
                        // like a reels feed: swipe up for the next matchup,
                        // down for the previous one; the page follows the
                        // finger and the neighbour slides in
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (d) =>
                            _onDragUpdate(d, votingService),
                        onVerticalDragEnd: (d) => _onDragEnd(d, votingService),
                        child: ClipRect(
                            child: pager(votingService, m, box.maxHeight)),
                      );
                    }),
            ),
            controls(votingService, m),
          ],
        ),
        if (_showTutorial) tutorial(),
      ],
    );
  }

  /// The current page, plus the neighbour coming in while it moves. Pages
  /// are keyed, so the one that slid in keeps its place once it becomes
  /// current.
  Widget pager(VotingService votingService, Matchup? m, double height) {
    Widget page(Matchup? matchup, double dy, {bool current = false}) {
      return Transform.translate(
        key: ValueKey(matchup?.id ?? '_caughtUp'),
        offset: Offset(0, dy),
        child: IgnorePointer(
          ignoring: !current,
          child: matchup == null
              ? caughtUp()
              : matchupView(votingService, matchup),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_refreshing || _pullsToRefresh(votingService)) refreshIndicator(),
        if (_offset > 0 && votingService.canGoBack)
          page(votingService.peek(-1), _offset - height),
        page(m, _offset, current: true),
        if (_offset < 0 && votingService.canGoNext)
          page(votingService.peek(1), _offset + height),
      ],
    );
  }

  /// Shows above the page while pulling down to refresh: an arrow that
  /// turns once the pull is far enough, then a spinner while loading
  Widget refreshIndicator() {
    final ready = _offset >= refreshPull;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: _offset.clamp(0.0, double.infinity),
      child: Center(
        child: _refreshing
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.amberAccent))
            : Opacity(
                opacity: (_offset / refreshPull).clamp(0.0, 1.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: ready ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(Icons.arrow_downward_rounded,
                          color: Colors.amberAccent, size: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(ready ? 'Release to refresh' : 'Pull to refresh',
                        style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'OpenSans',
                            fontSize: 13)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget matchupView(VotingService votingService, Matchup m) {
    MatchupVote? myVote = votingService.voteFor(m);
    return Column(
      children: [
        promptBox(m),
        for (int card = 0; card < 2; card++)
          Expanded(
            flex: 4,
            child: VoteCard(
              answer: m.answers[card],
              accent: answerColors[card],
              myVote: myVote,
              author: votingService.authorsFor(m)?[card],
              card: card,
              pickPercent: m.pickPercent(card),
              onVote: (type) => onVote(m, card, type),
              onOpenComments: () => openComments(m, card),
              onHold: () => openAnswerMenu(m, card),
            ),
          ),
        if (myVote != null) commentsPreview(m, myVote.card),
      ],
    );
  }

  Widget promptBox(Matchup m) {
    double width = MediaQuery.of(context).size.width;
    return Expanded(
      flex: 2,
      child: Semantics(
        onLongPressHint: 'Hide this prompt',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: () => openPromptMenu(m),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(width / 30, 0, width / 30, 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 5)),
            child: Center(
              child: AutoSizeText.rich(
                TextSpan(
                  style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontFamily: 'OpenSans'),
                  children: [
                    TextSpan(text: m.promptBefore),
                    const TextSpan(
                        text: '____________',
                        style: TextStyle(color: Colors.amber)),
                    TextSpan(text: m.promptAfter),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                minFontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Comments on the answer the user just picked or downvoted: its count
  /// and latest comment, copied into the matchup so this costs no reads.
  /// Tapping the other card opens that answer's thread instead.
  Widget commentsPreview(Matchup m, int card) {
    double width = MediaQuery.of(context).size.width;
    final answer = m.answers[card];
    final latest = answer.preview.isEmpty ? null : answer.preview.last;
    return GestureDetector(
      onTap: () => openComments(m, card),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: width / 30, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline,
                color: answerColors[card], size: 18),
            const SizedBox(width: 8),
            Text(
                answer.commentCount == 0
                    ? 'Comments'
                    : 'Comments (${answer.commentCount})',
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Expanded(
              child: latest == null
                  ? const SizedBox()
                  : Text('${latest.username}: ${latest.text}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontFamily: 'OpenSans')),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget controls(VotingService votingService, Matchup? m) {
    bool voted = m != null && votingService.hasVoted(m);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous matchup',
            onPressed: votingService.canGoBack ? _goBack : null,
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
          const Spacer(),
          if (m != null)
            TextButton.icon(
              onPressed: _goNext,
              icon: const Icon(Icons.keyboard_double_arrow_down,
                  color: Colors.amberAccent),
              label: Text(voted ? 'Next' : 'Skip',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                      fontSize: 16)),
            ),
        ],
      ),
    );
  }

  Widget caughtUp() {
    final voting = Provider.of<VotingService>(context, listen: false);
    final filter = voting.filter;
    final none = voting.countFor(filter) == 0;
    final String message = switch ((filter, none)) {
      (MatchupFilter.friends, true) =>
        "No friend prompts to vote on yet.\nWhen your friends write prompts, "
            "their matchups show up here.",
      (MatchupFilter.global, true) =>
        'No public matchups yet.\nThey show up as people answer.',
      (MatchupFilter.all, true) =>
        'No matchups yet.\nThey show up as people answer.',
      _ => "You're all caught up!\nNew matchups show up as people answer.",
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white, fontFamily: 'OpenSans', fontSize: 20),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => loadMatchups(force: true),
              icon: const Icon(Icons.refresh, color: Colors.amberAccent),
              label: const Text('Check for new matchups',
                  style:
                      TextStyle(color: Colors.white, fontFamily: 'OpenSans')),
            ),
          ],
        ),
      ),
    );
  }

  Widget tutorial() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('How to vote',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            tutorialRow(Icons.swipe_right, Colors.amberAccent,
                'Swipe right on the winner'),
            tutorialRow(
                Icons.swipe_left, Colors.redAccent, 'Swipe left to downvote'),
            tutorialRow(Icons.swipe_up, Colors.white, 'Swipe up to skip'),
            tutorialRow(Icons.swipe_down, Colors.white,
                'Swipe down to see your last one'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: dismissTutorial,
              style: const ButtonStyle(
                  backgroundColor:
                      WidgetStatePropertyAll<Color>(Colors.amberAccent)),
              child: const Text('Got it',
                  style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget tutorialRow(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'OpenSans', fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
