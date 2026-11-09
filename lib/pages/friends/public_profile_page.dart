import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/account.dart';
import '../../data/awards.dart';
import '../../data/friends.dart';
import '../../data/prompt_day.dart';
import '../../state/friends_service.dart';
import '../../state/session_service.dart';
import '../accountpage/account.dart' show HeaderStat;
import '../createpage/create_stats.dart' show FriendAvatar;

/// How the signed-in user stands with the person on the profile
enum ProfileRelation { loading, notFound, you, friends, theyAsked, none }

/// Someone else's profile, opened by tapping an answer's author after you
/// vote. Strangers see only the username and photo and can send a friend
/// request; friends also see their stats and awards (FriendView is readable
/// by friends).
class PublicProfilePage extends StatefulWidget {
  final String username;
  final String photoUrl;

  const PublicProfilePage(
      {super.key, required this.username, this.photoUrl = ''});

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  FriendCard? _them;
  AccountProfile? _profile;
  List<AwardTrack> _catalog = const [];
  bool _looked = false;
  bool _busy = false;
  bool _requested = false;
  String? _message;

  FirebaseFirestore get _firestore =>
      Provider.of<FirebaseFirestore>(context, listen: false);
  SessionService get _session =>
      Provider.of<SessionService>(context, listen: false);
  FriendsService get _friends =>
      Provider.of<FriendsService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final me = _session.loggedInUser;
    try {
      final them = await findUserByUsername(_firestore, widget.username);
      if (!_friends.loaded && me?.uid != null) {
        await _friends.load(_firestore, me!.uid!, _session.email);
      }
      if (!mounted) return;
      setState(() {
        _them = them;
        _looked = true;
      });
      await _loadFriendView();
    } catch (e) {
      debugPrint('profile lookup: $e');
      if (mounted) setState(() => _looked = true);
    }
  }

  /// A friend's stats and awards
  Future<void> _loadFriendView() async {
    final them = _them;
    if (them == null || _relation() != ProfileRelation.friends) return;
    try {
      final results = await Future.wait([
        getProfile(_firestore, them.uid),
        _catalog.isEmpty ? loadAwardCatalog() : Future.value(_catalog),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as AccountProfile;
        _catalog = results[1] as List<AwardTrack>;
      });
    } catch (e) {
      debugPrint('friend profile: $e');
    }
  }

  ProfileRelation _relation() {
    if (!_looked) return ProfileRelation.loading;
    final them = _them;
    if (them == null) return ProfileRelation.notFound;
    if (them.uid == _session.loggedInUser?.uid) return ProfileRelation.you;
    final friends = Provider.of<FriendsService>(context, listen: false);
    if (friends.friends.any((f) => f.uid == them.uid)) {
      return ProfileRelation.friends;
    }
    if (friends.requests.any((r) => r.uid == them.uid)) {
      return ProfileRelation.theyAsked;
    }
    return ProfileRelation.none;
  }

  Future<void> _addFriend() async {
    final me = _session.loggedInUser;
    if (me == null || _busy) return;
    setState(() => _busy = true);
    String? message;
    try {
      final result =
          await _friends.send(_firestore, me, widget.username, _session.email);
      switch (result) {
        case FriendRequestResult.sent:
          _requested = true;
        case FriendRequestResult.accepted:
          message = "They'd already asked you. You're now friends!";
        case FriendRequestResult.alreadyFriends:
          message = "You're already friends.";
        case FriendRequestResult.notAllowed:
          message = "This account can't be added as a friend.";
        case FriendRequestResult.notFound:
          message = 'This account no longer exists.';
        case FriendRequestResult.isYou:
          message = "That's you!";
      }
    } catch (e) {
      // a request already waiting can't be written again
      debugPrint('friend request: $e');
      _requested = true;
      message = 'Your request is waiting for them to accept.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = message;
    });
    await _loadFriendView();
  }

  Future<void> _accept() async {
    final me = _session.loggedInUser;
    final card = _friends.requests.where((r) => r.uid == _them?.uid);
    if (me == null || card.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await _friends.accept(_firestore, me, card.first, _session.email);
    } catch (e) {
      debugPrint('accept: $e');
      _message = "Couldn't accept. Try again.";
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _loadFriendView();
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<FriendsService>(context); // rebuild when friends change
    final relation = _relation();
    final photo =
        _them?.photoUrl.isNotEmpty == true ? _them!.photoUrl : widget.photoUrl;
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Center(
            child: photo.isNotEmpty
                ? CircleAvatar(radius: 52, backgroundImage: NetworkImage(photo))
                : FriendAvatar(
                    username: widget.username,
                    index: widget.username.codeUnits.fold(0, (a, b) => a + b),
                    radius: 52),
          ),
          const SizedBox(height: 14),
          Text(widget.username,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 24)),
          const SizedBox(height: 20),
          Center(child: _action(relation)),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontFamily: 'OpenSans')),
            ),
          const SizedBox(height: 28),
          if (relation == ProfileRelation.friends)
            _friendDetails()
          else if (relation == ProfileRelation.none ||
              relation == ProfileRelation.theyAsked)
            const Text('Become friends to see their stats, streak and awards.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white54, fontFamily: 'OpenSans')),
        ],
      ),
    );
  }

  Widget _action(ProfileRelation relation) {
    Widget button(String label, IconData icon, VoidCallback? onPressed,
            {bool filled = true}) =>
        FilledButton.icon(
          onPressed: _busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: filled ? Colors.amberAccent : Colors.white12,
            foregroundColor: filled ? Colors.black : Colors.white,
            disabledBackgroundColor: Colors.white12,
            disabledForegroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          icon: Icon(icon, size: 20),
          label: Text(label,
              style: const TextStyle(
                  fontFamily: 'OpenSans', fontWeight: FontWeight.bold)),
        );

    return switch (relation) {
      ProfileRelation.loading => const SizedBox(
          height: 44,
          child: Center(child: CircularProgressIndicator(color: Colors.amber))),
      ProfileRelation.notFound => const Text('This account no longer exists.',
          style: TextStyle(color: Colors.white54)),
      ProfileRelation.you =>
        const Text("That's you!", style: TextStyle(color: Colors.white54)),
      ProfileRelation.friends =>
        button('Friends', Icons.check_rounded, null, filled: false),
      ProfileRelation.theyAsked =>
        button('Accept friend request', Icons.person_add_alt_1, _accept),
      ProfileRelation.none => _requested
          ? button('Requested', Icons.schedule_rounded, null, filled: false)
          : button('Add friend', Icons.person_add_alt_1, _addFriend),
    };
  }

  Widget _friendDetails() {
    final p = _profile;
    if (p == null) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.amber));
    }
    final todayId = promptDayId(DateTime.now().toUtc());
    final earned = [
      for (final a in awardProgress(_catalog, p.data))
        for (final t in a.earnedTiers) t.name,
    ];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            HeaderStat(label: 'Posts', value: p.answers),
            HeaderStat(label: 'Wins', value: p.wins),
            HeaderStat(label: 'Streak', value: p.streak.currentAsOf(todayId)),
          ],
        ),
        const SizedBox(height: 24),
        if (earned.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in earned)
                Chip(
                  avatar: const Icon(Icons.emoji_events,
                      color: Colors.amber, size: 18),
                  label: Text(name),
                  backgroundColor: Colors.white10,
                  side: BorderSide.none,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
            ],
          ),
      ],
    );
  }
}
