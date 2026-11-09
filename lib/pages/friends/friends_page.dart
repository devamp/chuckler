import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../data/friends.dart';
import '../../state/friends_service.dart';
import '../../state/session_service.dart';
import '../createpage/create_stats.dart';

/// Add friends by username or email, answer requests, and see your friends
class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final TextEditingController _add = TextEditingController();
  bool _sending = false;

  /// the last send's outcome, shown under the box
  String? _message;
  bool _messageIsError = false;

  FirebaseFirestore get _firestore =>
      Provider.of<FirebaseFirestore>(context, listen: false);
  SessionService get _session =>
      Provider.of<SessionService>(context, listen: false);
  FriendsService get _friends =>
      Provider.of<FriendsService>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final uid = _session.loggedInUser?.uid;
    if (uid == null) return;
    await _friends.load(_firestore, uid, _session.email);
  }

  Future<void> _send() async {
    final me = _session.loggedInUser;
    final input = _add.text.trim();
    if (me == null || input.isEmpty || _sending) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    String message;
    bool error = true;
    try {
      final result =
          await _friends.send(_firestore, me, input, _session.email);
      final email = looksLikeEmail(input);
      (message, error) = switch (result) {
        FriendRequestResult.sent => (
            email
                ? "Request sent. If someone has that email, they'll see it."
                : 'Request sent to $input.',
            false
          ),
        FriendRequestResult.accepted => (
            'They had already asked you. You\'re now friends!',
            false
          ),
        FriendRequestResult.notFound => ('No one has that username.', true),
        FriendRequestResult.isYou => ("That's you!", true),
        FriendRequestResult.alreadyFriends => (
            "You're already friends.",
            true
          ),
        FriendRequestResult.notAllowed => (
            "That account can't be added as a friend.",
            true
          ),
      };
      if (!error) _add.clear();
    } catch (e) {
      debugPrint('friend request: $e');
      message = "Couldn't send that request. Try again.";
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _message = message;
      _messageIsError = error;
    });
  }

  Future<void> _act(Future<void> Function() action, String failure) async {
    try {
      await action();
    } catch (e) {
      debugPrint('friends: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure)));
      }
    }
  }

  Future<void> _confirmRemove(FriendCard friend) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${friend.username}?'),
        content: const Text(
            "You'll stop being friends. They won't be told, but they can send you a new request."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (yes == true && mounted) {
      final uid = _session.loggedInUser!.uid!;
      await _act(() => _friends.remove(_firestore, uid, friend),
          "Couldn't remove ${friend.username}.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final friends = Provider.of<FriendsService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: primaryBackgroundGradient(context)),
        child: RefreshIndicator(
          color: Colors.amber,
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _addBox(),
              if (friends.requests.isNotEmpty) ...[
                _heading('Requests (${friends.requests.length})'),
                for (final r in friends.requests) _requestRow(r),
              ],
              _heading('Your friends (${friends.friendCount})'),
              if (!friends.loaded)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.amber)),
                )
              else if (friends.friends.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                      'No friends yet. Add someone by their username or email.',
                      style: _muted),
                )
              else
                for (final f in friends.friends) _friendRow(f),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add a friend',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _add,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'OpenSans'),
                decoration: InputDecoration(
                  hintText: 'Username or email',
                  hintStyle: _muted,
                  filled: true,
                  fillColor: Colors.black54,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent,
                  foregroundColor: Colors.black),
              child: const Text('Send',
                  style: TextStyle(
                      fontFamily: 'OpenSans', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_message!,
                style: TextStyle(
                    color:
                        _messageIsError ? Colors.redAccent : Colors.greenAccent,
                    fontFamily: 'OpenSans')),
          ),
      ],
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: Colors.amber,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      );

  Widget _avatar(FriendCard f) => f.photoUrl.isNotEmpty
      ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(f.photoUrl))
      : FriendAvatar(
          username: f.username,
          index: f.username.codeUnits.fold(0, (a, b) => a + b),
          radius: 20);

  Widget _name(FriendCard f) => Text(f.username,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          color: Colors.white,
          fontFamily: 'OpenSans',
          fontWeight: FontWeight.bold,
          fontSize: 16));

  Widget _requestRow(FriendCard r) {
    final me = _session.loggedInUser!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(r),
          const SizedBox(width: 12),
          Expanded(child: _name(r)),
          TextButton(
            onPressed: () => _act(
                () => _friends.decline(_firestore, me.uid!, r, _session.email),
                "Couldn't decline that request."),
            child: const Text('Decline', style: _muted),
          ),
          ElevatedButton(
            onPressed: () => _act(
                () => _friends.accept(_firestore, me, r, _session.email),
                "Couldn't accept that request."),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent,
                foregroundColor: Colors.black),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  Widget _friendRow(FriendCard f) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _avatar(f),
          const SizedBox(width: 12),
          Expanded(child: _name(f)),
          PopupMenuButton<String>(
            tooltip: 'More for ${f.username}',
            icon: const Icon(Icons.more_horiz, color: Colors.white70),
            onSelected: (_) => _confirmRemove(f),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'remove', child: Text('Remove friend')),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _muted =
      TextStyle(color: Colors.white54, fontFamily: 'OpenSans');
}
