import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/friends.dart';
import '../database/models.dart';

/// The user's friends and the requests waiting for them, for the Friends
/// screen and the badge on the Account tab
class FriendsService with ChangeNotifier {
  List<FriendCard> _friends = const [];
  List<FriendCard> _requests = const [];
  bool _loaded = false;

  List<FriendCard> get friends => _friends;
  List<FriendCard> get requests => _requests;
  int get friendCount => _friends.length;
  int get pendingCount => _requests.length;
  bool get loaded => _loaded;

  /// Reads friends and requests. [myEmail] finds requests sent by email.
  Future<void> load(
      FirebaseFirestore firestore, String uid, String? myEmail) async {
    try {
      final results = await Future.wait([
        getFriends(firestore, uid),
        getFriendRequests(firestore, uid, myEmail),
      ]);
      _friends = results[0];
      _requests = results[1];
      _loaded = true;
    } catch (e) {
      debugPrint('friends: $e');
    }
    notifyListeners();
  }

  /// Sends a request to a username, or to an email when [input] has an @.
  /// Returns what happened, for the screen's message. Throws if the write
  /// is refused.
  Future<FriendRequestResult> send(FirebaseFirestore firestore, DbUser me,
      String input, String? myEmail) async {
    final text = input.trim();
    if (looksLikeEmail(text)) {
      if (myEmail != null && emailHash(text) == emailHash(myEmail)) {
        return FriendRequestResult.isYou;
      }
      await sendEmailFriendRequest(firestore, me, text);
      return FriendRequestResult.sent;
    }
    final result = await sendFriendRequest(firestore, me, text);
    if (result == FriendRequestResult.accepted) {
      await load(firestore, me.uid!, myEmail);
    }
    return result;
  }

  /// Accepts a request; they move from requests to friends
  Future<void> accept(FirebaseFirestore firestore, DbUser me, FriendCard them,
      String? myEmail) async {
    await acceptFriendRequest(firestore, me, them, myEmail: myEmail);
    _requests = _requests.where((r) => r.uid != them.uid).toList();
    _friends = [
      ..._friends.where((f) => f.uid != them.uid),
      FriendCard(them.uid, them.username, them.photoUrl),
    ]..sort((a, b) =>
        a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    notifyListeners();
  }

  Future<void> decline(FirebaseFirestore firestore, String myUid,
      FriendCard them, String? myEmail) async {
    await declineFriendRequest(firestore, myUid, them, myEmail: myEmail);
    _requests = _requests.where((r) => r.uid != them.uid).toList();
    notifyListeners();
  }

  Future<void> remove(
      FirebaseFirestore firestore, String myUid, FriendCard them) async {
    await removeFriend(firestore, myUid, them.uid);
    _friends = _friends.where((f) => f.uid != them.uid).toList();
    notifyListeners();
  }

  void logout() {
    _friends = const [];
    _requests = const [];
    _loaded = false;
    notifyListeners();
  }
}
