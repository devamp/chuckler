import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/moderation.dart';
import '../state/friends_service.dart';
import '../state/moderation_service.dart';
import '../state/session_service.dart';

// The hold menu: holding an answer, prompt, comment or person opens a sheet
// of what you can do with it (hide, report, block). Shared by every screen
// so they look and behave the same.

const _sheetColor = Color(0xFF1C1C1E);

/// One row in a hold menu
class HoldAction {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool danger;
  final Future<void> Function() run;

  const HoldAction(
      {required this.icon,
      required this.label,
      this.subtitle,
      this.danger = false,
      required this.run});
}

/// Opens the sheet a hold shows: an optional [header] (what was held) and
/// its [actions]. Runs the chosen action after the sheet closes.
Future<void> showHoldMenu(BuildContext context,
    {Widget? header, required List<HoldAction> actions}) async {
  HapticFeedback.mediumImpact();
  final chosen = await showModalBottomSheet<HoldAction>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: _sheetColor,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: header),
          for (final a in actions)
            ListTile(
              leading: Icon(a.icon,
                  color: a.danger ? Colors.redAccent : Colors.white),
              title: Text(a.label,
                  style: TextStyle(
                      color: a.danger ? Colors.redAccent : Colors.white,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold)),
              subtitle: a.subtitle == null
                  ? null
                  : Text(a.subtitle!,
                      style: const TextStyle(
                          color: Colors.white54, fontFamily: 'OpenSans')),
              onTap: () => Navigator.of(context).pop(a),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (chosen != null) await chosen.run();
}

/// A held prompt shown as text with its blank, for a menu header
Widget promptHeader(String before, String after) => Text.rich(
      TextSpan(children: [
        TextSpan(text: before),
        const TextSpan(text: '____', style: TextStyle(color: Colors.amber)),
        TextSpan(text: after),
      ]),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          color: Colors.white70, fontFamily: 'OpenSans', fontSize: 15),
    );

/// A held answer or comment shown as quoted text, for a menu header
Widget quoteHeader(String text) => Text('“$text”',
    maxLines: 3,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
        color: Colors.white70, fontFamily: 'OpenSans', fontSize: 15));

/// Asks why something is being reported
Future<ReportReason?> pickReportReason(BuildContext context, String what) {
  return showModalBottomSheet<ReportReason>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: _sheetColor,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text('Why are you reporting this $what?',
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 17)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
                "We'll review it. Whoever posted it isn't told who "
                'reported it.',
                style:
                    TextStyle(color: Colors.white54, fontFamily: 'OpenSans')),
          ),
          for (final r in ReportReason.values)
            ListTile(
              title: Text(r.label,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'OpenSans')),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () => Navigator.of(context).pop(r),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Asks to confirm blocking [username]
Future<bool> confirmBlock(BuildContext context, String username) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: _sheetColor,
      title:
          Text('Block $username?', style: const TextStyle(color: Colors.white)),
      content: const Text(
          "You'll stop being friends, and you won't see their answers, "
          "comments or prompts. They won't be told. You can unblock them in "
          'Settings.',
          style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70))),
        TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Block',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold))),
      ],
    ),
  );
  return yes == true;
}

String _myUid(BuildContext context) =>
    Provider.of<SessionService>(context, listen: false).loggedInUser?.uid ?? '';

/// Reports something after asking why, and says thanks. [what] names it in
/// the question ("answer", "comment", "prompt", "account").
Future<void> reportFlow(
  BuildContext context, {
  required String what,
  required ReportTarget target,
  required String targetId,
  String? postId,
  String? matchupId,
}) async {
  final reason = await pickReportReason(context, what);
  if (reason == null || !context.mounted) return;
  final moderation = Provider.of<ModerationService>(context, listen: false);
  final firestore = Provider.of<FirebaseFirestore>(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await moderation.report(firestore,
        reporter: _myUid(context),
        target: target,
        targetId: targetId,
        reason: reason,
        postId: postId,
        matchupId: matchupId);
    messenger?.showSnackBar(const SnackBar(
        content: Text("Thanks for reporting. We'll review it.")));
  } catch (e) {
    debugPrint('report: $e');
    messenger?.showSnackBar(
        const SnackBar(content: Text("Couldn't send your report. Try again.")));
  }
}

/// Blocks someone after confirming. Pass their [uid] if known; otherwise
/// it's looked up from [username]. [matchupId] (the matchup on screen)
/// leaves the queue at once.
Future<void> blockFlow(
  BuildContext context, {
  required String username,
  String? uid,
  String photoUrl = '',
  String? matchupId,
}) async {
  if (!await confirmBlock(context, username) || !context.mounted) return;
  final moderation = Provider.of<ModerationService>(context, listen: false);
  final friends = Provider.of<FriendsService>(context, listen: false);
  final session = Provider.of<SessionService>(context, listen: false);
  final firestore = Provider.of<FirebaseFirestore>(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final me = _myUid(context);
  try {
    final them = uid ?? await uidForUsername(firestore, username);
    if (them == null || them == me) throw StateError('no such user');
    await moderation.block(firestore, me, BlockedUser(them, username, photoUrl),
        matchupId: matchupId);
    messenger?.showSnackBar(SnackBar(content: Text('Blocked $username')));
    // the server unfriends them; show the list without them
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await friends.load(firestore, me, session.email);
  } catch (e) {
    debugPrint('block: $e');
    messenger?.showSnackBar(
        const SnackBar(content: Text("Couldn't block them. Try again.")));
  }
}

/// Report and Block, for holding a person (profile, leaderboard row)
List<HoldAction> personActions(BuildContext context,
        {required String username, String? uid, String photoUrl = ''}) =>
    [
      HoldAction(
          icon: Icons.flag_outlined,
          label: 'Report $username',
          run: () async {
            final id = uid ??
                await uidForUsername(
                    Provider.of<FirebaseFirestore>(context, listen: false),
                    username);
            if (id == null || !context.mounted) return;
            await reportFlow(context,
                what: 'account', target: ReportTarget.user, targetId: id);
          }),
      HoldAction(
          icon: Icons.block,
          label: 'Block $username',
          danger: true,
          run: () => blockFlow(context,
              username: username, uid: uid, photoUrl: photoUrl)),
    ];
