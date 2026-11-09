import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../data/account.dart';
import '../../data/prompt_day.dart';
import '../../state/account_service.dart';
import '../../state/session_service.dart';

/// "Today", "Yesterday" or "Nov 8" for a prompt day, relative to [todayId]
String dayLabel(String dayId, String todayId) {
  if (dayId == todayId) return 'Today';
  if (dayId.isEmpty) return '';
  final day = promptDayDate(dayId);
  final today = promptDayDate(todayId);
  if (today.difference(day).inDays == 1) return 'Yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final label = '${months[day.month - 1]} ${day.day}';
  return day.year == today.year ? label : '$label, ${day.year}';
}

/// The Account tab's Posts: the user's answers, newest first
class AccountPosts extends StatelessWidget {
  const AccountPosts({super.key});

  @override
  Widget build(BuildContext context) {
    final account = Provider.of<AccountService>(context);
    final todayId = promptDayId(DateTime.now().toUtc());

    if (!account.loaded) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    if (account.answers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text("You haven't answered anything yet",
              style: TextStyle(color: Colors.white70, fontSize: 16)),
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 5),
        for (final a in account.answers) AnswerCard(entry: a, todayId: todayId),
        if (account.hasMoreAnswers)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: account.loadingMore
                ? const CircularProgressIndicator(color: Colors.amber)
                : TextButton(
                    onPressed: () {
                      final uid =
                          Provider.of<SessionService>(context, listen: false)
                              .loggedInUser
                              ?.uid;
                      if (uid == null) return;
                      account.loadMoreAnswers(
                          Provider.of<FirebaseFirestore>(context,
                              listen: false),
                          uid);
                    },
                    child: const Text('Load more',
                        style: TextStyle(color: Colors.amber)),
                  ),
          ),
      ],
    );
  }
}

/// One answer: the prompt with the answer in the blank, its day and how it
/// did
class AnswerCard extends StatelessWidget {
  final AnswerEntry entry;
  final String todayId;

  const AnswerCard({super.key, required this.entry, required this.todayId});

  @override
  Widget build(BuildContext context) {
    final r = entry.result;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(dayLabel(entry.promptDateId, todayId),
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const Spacer(),
                if (!r.isFinal)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Text('Live',
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: entry.before),
                TextSpan(
                    text: entry.answer,
                    style: const TextStyle(
                        color: Color(0xFFffd230), fontWeight: FontWeight.bold)),
                TextSpan(text: entry.after),
              ]),
              style: const TextStyle(
                  fontSize: 16, color: Colors.white, height: 1.3),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _stat(FontAwesomeIcons.trophy, r.wins,
                    r.wins == 1 ? 'win' : 'wins'),
                _stat(FontAwesomeIcons.checkToSlot, r.votes,
                    r.votes == 1 ? 'vote' : 'votes'),
                _stat(FontAwesomeIcons.comment, r.comments,
                    r.comments == 1 ? 'comment' : 'comments'),
                if (r.isFinal && r.winRate != null)
                  Text('${(r.winRate! * 100).round()}% win rate',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(FaIconData icon, int n, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 13, color: Colors.white70),
          const SizedBox(width: 5),
          Text('$n $label',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      );
}
