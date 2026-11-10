import 'package:chuckler/pages/accountpage/account_awards.dart';
import 'package:chuckler/pages/accountpage/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:provider/provider.dart';
import '../../state/account_service.dart';
import '../../state/session_service.dart';
import '../../Theme/theme.dart';
import 'account_notifications.dart';
import 'account_posts.dart';
import '../friends/friends_page.dart';
import '../../state/friends_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;

/// The Account tab: the user's header (Posts, Friends, Wins), then their
/// answers, notifications and achievements. Live from Firestore through
/// AccountService and FriendsService.
class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  Future<void> _reload() async {
    final session = Provider.of<SessionService>(context, listen: false);
    final uid = session.loggedInUser?.uid;
    if (uid == null) return;
    final firestore = Provider.of<FirebaseFirestore>(context, listen: false);
    await Future.wait([
      Provider.of<AccountService>(context, listen: false).load(firestore, uid),
      Provider.of<FriendsService>(context, listen: false)
          .load(firestore, uid, session.email),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final Widget tab = switch (_currentPageIndex) {
      1 => const AccountNotifications(),
      2 => const AwardsPage(),
      _ => const AccountPosts(),
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: primaryBackgroundGradient(context),
        ),
        child: Column(
          children: [
            accountHeader(context, screenWidth),
            Expanded(
              child: RefreshIndicator(
                color: Colors.amber,
                onRefresh: _reload,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [tab],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget accountHeader(BuildContext context, double screenWidth) {
    SessionService sessionService =
        Provider.of<SessionService>(context, listen: true);
    final account = Provider.of<AccountService>(context);
    final profile = account.profile;

    return Container(
      width: screenWidth,
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35.0),
          bottomRight: Radius.circular(35.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ProfilePicture(
                name:
                    profilePictureName(sessionService.loggedInUser!.username!),
                radius: 55,
                fontsize: 20),
            const SizedBox(height: 12),
            Text(
              sessionService.loggedInUser!.username!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeaderStat(
                    label: 'Posts',
                    value: account.loaded ? profile.answers : null),
                const SizedBox(width: 40),
                const FriendsStat(),
                const SizedBox(width: 40),
                HeaderStat(
                    label: 'Wins', value: account.loaded ? profile.wins : null),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Settings()),
                    );
                  },
                  style: const ButtonStyle(
                    backgroundColor:
                        WidgetStatePropertyAll<Color>(Colors.white),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.settings, color: Colors.black, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            buildNavBar(context, account.unseenCount),
          ],
        ),
      ),
    );
  }

  Widget buildNavBar(BuildContext context, int unseen) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.transparent,
      currentIndex: _currentPageIndex,
      onTap: (itemIndex) => setState(() => _currentPageIndex = itemIndex),
      selectedItemColor: const Color(0xFFffd230),
      unselectedItemColor: Colors.white,
      items: [
        const BottomNavigationBarItem(
          label: "Posts",
          icon: Icon(Icons.sticky_note_2_outlined),
        ),
        BottomNavigationBarItem(
          label: "Notifications",
          icon: Badge(
            isLabelVisible: unseen > 0,
            smallSize: 9,
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.notifications),
          ),
        ),
        const BottomNavigationBarItem(
          label: "Achievements",
          icon: Icon(Icons.verified_rounded),
        ),
      ],
    );
  }
}

/// 1234 -> "1,234"; 12345 -> "12.3K"; 1234567 -> "1.2M"
String compactCount(int n) {
  if (n >= 1000000) {
    return '${(n / 1000000).toStringAsFixed(n >= 10000000 ? 0 : 1)}M';
  }
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(n >= 100000 ? 0 : 1)}K';
  final s = n.toString();
  return s.length > 3
      ? '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'
      : s;
}

/// A number over a label in the Account header; "–" while [value] is null
class HeaderStat extends StatelessWidget {
  final String label;
  final int? value;

  const HeaderStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value == null ? '–' : compactCount(value!),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.amber),
        ),
      ],
    );
  }
}

/// The Friends count in the Account header, with a badge for waiting
/// requests. Tap to open the Friends screen. The Account tab loads friends.
class FriendsStat extends StatelessWidget {
  const FriendsStat({super.key});

  @override
  Widget build(BuildContext context) {
    final friends = Provider.of<FriendsService>(context);
    return Tooltip(
      message: 'Friends',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const FriendsPage())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Badge(
            isLabelVisible: friends.pendingCount > 0,
            label: Text('${friends.pendingCount}'),
            backgroundColor: Colors.redAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  friends.loaded ? compactCount(friends.friendCount) : '–',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Friends',
                  style: TextStyle(fontSize: 16, color: Colors.amber),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
