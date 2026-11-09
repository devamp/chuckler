import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/matchups.dart';
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

class _VotePageState extends State<VotePage> {
  final List<Color> answerColors = [Colors.greenAccent, Colors.purpleAccent];
  double _dragDy = 0;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    loadMatchups();
    checkTutorial();
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
    String uid = Provider.of<SessionService>(context, listen: false)
            .loggedInUser
            ?.uid ??
        '';
    final myPostIds = {
      for (final p in Provider.of<PromptService>(context, listen: false)
          .userPostsForPrompts)
        if ((p?.postId ?? '').isNotEmpty) p!.postId!,
    };
    List<Matchup> matchups = [];
    try {
      matchups = await getVotingMatchups(firestore, uid, myPostIds);
    } catch (e) {
      debugPrint('matchups: $e');
    }
    votingService.setMatchups(matchups, myPostIds);
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

  /// Opens the comment thread of one answer
  void openComments(Matchup m, int card) {
    showAnswerComments(context,
        matchup: m,
        card: card,
        accent: answerColors[card],
        canComment: Provider.of<VotingService>(context, listen: false)
            .hasVoted(m));
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
                  : GestureDetector(
                      // like a reels feed: swipe up for the next matchup,
                      // down for the previous one
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (_) => _dragDy = 0,
                      onVerticalDragUpdate: (d) => _dragDy += d.delta.dy,
                      onVerticalDragEnd: (d) {
                        double speed = d.velocity.pixelsPerSecond.dy;
                        if (_dragDy < -80 || (_dragDy < -20 && speed < -600)) {
                          votingService.next();
                        } else if (_dragDy > 80 ||
                            (_dragDy > 20 && speed > 600)) {
                          votingService.back();
                        }
                      },
                      child: m == null
                          ? caughtUp()
                          : matchupView(votingService, m),
                    ),
            ),
            controls(votingService, m),
          ],
        ),
        if (_showTutorial) tutorial(),
      ],
    );
  }

  Widget matchupView(VotingService votingService, Matchup m) {
    MatchupVote? myVote = votingService.voteFor(m);
    return Column(
      key: ValueKey(m.id),
      children: [
        promptBox(m),
        for (int card = 0; card < 2; card++)
          Expanded(
            flex: 4,
            child: VoteCard(
              answer: m.answers[card],
              segment: m.segment,
              accent: answerColors[card],
              myVote: myVote,
              author: votingService.authorsFor(m)?[card],
              card: card,
              pickPercent: m.pickPercent(card),
              onVote: (type) => onVote(m, card, type),
              onOpenComments: () => openComments(m, card),
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
                  fontSize: 26, color: Colors.white, fontFamily: 'OpenSans'),
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
            Icon(Icons.chat_bubble_outline, color: answerColors[card], size: 18),
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
            onPressed: votingService.canGoBack ? votingService.back : null,
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.white,
            disabledColor: Colors.white24,
          ),
          const Spacer(),
          if (m != null)
            TextButton.icon(
              onPressed: votingService.next,
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
                  style: TextStyle(color: Colors.white, fontFamily: 'OpenSans')),
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
