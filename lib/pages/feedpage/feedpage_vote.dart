import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/matchups.dart';
import '../../state/session_service.dart';
import '../../state/voting_service.dart';
import 'feedpage_vote_card.dart';

const String voteTutorialSeenKey = 'voteTutorialSeen';

/// Swipe voting: two stacked answers to the same prompt. Swipe right on the
/// winner, left to downvote, down to skip or move on.
class VotePage extends StatefulWidget {
  const VotePage({super.key});

  @override
  State<VotePage> createState() => _VotePageState();
}

class _VotePageState extends State<VotePage> {
  final List<Color> answerColors = [Colors.greenAccent, Colors.purpleAccent];
  double _dragDown = 0;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    loadMatchups();
    checkTutorial();
  }

  Future<void> loadMatchups() async {
    VotingService votingService =
        Provider.of<VotingService>(context, listen: false);
    if (votingService.loaded) {
      return;
    }
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    String uid = Provider.of<SessionService>(context, listen: false)
            .loggedInUser
            ?.uid ??
        '';
    votingService.setMatchups(await getVotingMatchups(firestore, uid), uid);
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

  void onVote(Matchup m, int card, VoteType type) {
    VotingService votingService =
        Provider.of<VotingService>(context, listen: false);
    if (votingService.vote(card, type)) {
      castVote(
          Provider.of<FirebaseFirestore>(context, listen: false),
          Provider.of<SessionService>(context, listen: false)
                  .loggedInUser
                  ?.uid ??
              '',
          m,
          votingService.voteFor(m)!);
    }
  }

  void openComments(Matchup m) {
    // TODO(cloud): matchup comments need a new model keyed by matchup, e.g.
    // Comments with a matchupId field or MatchUps/{id}/Comments. The existing
    // Comments collection is keyed by postId and belongs to the Past feed.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => const SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'Matchup comments are coming soon',
            style: TextStyle(color: Colors.white, fontFamily: 'OpenSans'),
          ),
        ),
      ),
    );
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
                  : m == null
                      ? caughtUp()
                      : GestureDetector(
                          // swipe down anywhere on the matchup to move on
                          onVerticalDragStart: (_) => _dragDown = 0,
                          onVerticalDragUpdate: (d) =>
                              _dragDown += d.delta.dy,
                          onVerticalDragEnd: (d) {
                            // only a net downward swipe moves on; upward
                            // swipes never do, however fast they end
                            double speed = d.velocity.pixelsPerSecond.dy;
                            if (_dragDown > 80 ||
                                (_dragDown > 20 && speed > 600)) {
                              debugPrint(
                                  'Vote swipe down: moved $_dragDown px, speed $speed px/s');
                              votingService.next();
                            }
                          },
                          child: matchupView(votingService, m),
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
              card: card,
              pickPercent: m.pickPercent(card),
              onVote: (type) => onVote(m, card, type),
              onOpenComments: () => openComments(m),
            ),
          ),
        if (myVote != null) commentsPreview(m),
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

  Widget commentsPreview(Matchup m) {
    double width = MediaQuery.of(context).size.width;
    // TODO(cloud): show the first 2-3 matchup comments here once they exist.
    return GestureDetector(
      onTap: () => openComments(m),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: width / 30, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(20)),
        child: const Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.amberAccent, size: 18),
            SizedBox(width: 8),
            Text('Comments',
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold)),
            Spacer(),
            Icon(Icons.chevron_right, color: Colors.white),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          "You're all caught up!\nCheck Past for earlier prompts.",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontFamily: 'OpenSans', fontSize: 20),
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
            tutorialRow(Icons.swipe_down, Colors.white, 'Swipe down to skip'),
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
