import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/account.dart';
import '../../state/account_service.dart';
import '../../state/friends_service.dart';
import '../../state/session_service.dart';
import '../createpage/create_stats.dart' show FriendAvatar;
import '../friends/friends_page.dart';

/// Which heading a notification goes under, by the phone's local day
String notificationGroup(DateTime? at, DateTime now) {
  if (at == null) return 'Earlier';
  final today = DateTime(now.year, now.month, now.day);
  final local = at.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return 'Last 7 days';
  return 'Earlier';
}

const _groupOrder = ['Today', 'Yesterday', 'Last 7 days', 'Earlier'];

/// The Account tab's Notifications: waiting friend requests first, then the
/// notifications the server wrote, grouped by day. Opening it marks them
/// seen; the ones that were new keep their dot until the tab closes.
class AccountNotifications extends StatefulWidget {
  /// for tests
  final DateTime? now;

  const AccountNotifications({super.key, this.now});

  @override
  State<AccountNotifications> createState() => _AccountNotificationsState();
}

class _AccountNotificationsState extends State<AccountNotifications> {
  Set<String> _fresh = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());
  }

  void _markSeen() {
    if (!mounted) return;
    final account = Provider.of<AccountService>(context, listen: false);
    final uid =
        Provider.of<SessionService>(context, listen: false).loggedInUser?.uid;
    if (uid == null) return;
    final unseen = {
      for (final n in account.notifications)
        if (!n.seen) n.id
    };
    if (unseen.isEmpty) return;
    setState(() => _fresh = {..._fresh, ...unseen});
    account.markAllSeen(
        Provider.of<FirebaseFirestore>(context, listen: false), uid);
  }

  @override
  Widget build(BuildContext context) {
    final account = Provider.of<AccountService>(context);
    final requests = Provider.of<FriendsService>(context).pendingCount;
    // notifications that arrive (a refresh) while the tab is open
    if (account.notifications.any((n) => !n.seen)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());
    }

    final groups = <String, List<AppNotification>>{};
    final now = widget.now ?? DateTime.now();
    for (final n in account.notifications) {
      groups.putIfAbsent(notificationGroup(n.at, now), () => []).add(n);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (requests > 0) _requestsRow(context, requests),
          if (!account.loaded)
            const Padding(
              padding: EdgeInsets.all(28),
              child:
                  Center(child: CircularProgressIndicator(color: Colors.amber)),
            )
          else if (account.notifications.isEmpty && requests == 0)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: Text('No notifications yet',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ),
          for (final g in _groupOrder)
            if (groups[g] != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 4),
                child: Text(g,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ),
              for (final n in groups[g]!)
                NotificationRow(
                    notification: n, fresh: _fresh.contains(n.id) || !n.seen),
            ],
        ],
      ),
    );
  }

  Widget _requestsRow(BuildContext context, int n) => Material(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: const CircleAvatar(
            backgroundColor: Colors.amber,
            child: Icon(Icons.person_add, color: Colors.black),
          ),
          title: Text('Friend requests ($n)',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: const Text('Tap to accept or decline',
              style: TextStyle(color: Colors.white60)),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const FriendsPage())),
        ),
      );
}

/// One notification: the sender's avatar (or an icon for its kind), the
/// text, and a dot if it's new
class NotificationRow extends StatelessWidget {
  final AppNotification notification;
  final bool fresh;

  const NotificationRow(
      {super.key, required this.notification, this.fresh = false});

  static const _icons = {
    'friendRequest': Icons.person_add,
    'friendAdded': Icons.people,
    'award': Icons.emoji_events,
    'comment': Icons.chat_bubble,
    'results': Icons.bar_chart,
    'friendPrompt': Icons.edit_note,
  };

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final from = n.fromUsername;
    final Widget avatar = from != null
        ? (n.fromPhotoUrl?.isNotEmpty == true
            ? CircleAvatar(
                radius: 20, backgroundImage: NetworkImage(n.fromPhotoUrl!))
            : FriendAvatar(
                username: from,
                index: from.codeUnits.fold(0, (a, b) => a + b),
                radius: 20))
        : CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white12,
            child: Icon(_icons[n.type] ?? Icons.notifications,
                color: n.type == 'award' ? Colors.amber : Colors.white,
                size: 20),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Text(n.text,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: fresh ? FontWeight.bold : FontWeight.normal)),
          ),
          if (fresh)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                  color: Colors.redAccent, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
