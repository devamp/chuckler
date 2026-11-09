import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../database/models.dart';
import 'friend_prompts.dart';
import 'users.dart';

// Mutual friends, by uid (docs/data-model.md, Users). Uids stay inside the
// app: people find each other by username or email.
//   Users/{uid}/FriendRequests/{fromUid}      a request sent by username
//   EmailRequests/{emailHash}/From/{fromUid}  a request sent by email; only
//                                             that email's owner can read it
//   Users/{uid}/Friends/{friendUid}           one doc on each side
// Accepting writes both Friends docs and deletes the request in one batch;
// firestore.rules allow it only while the request exists.
//
// The legacy friend() at the bottom still serves the Past feed's profile
// popup, which reads the old username lists on Users.

/// A friend, or someone who sent the user a request
class FriendCard {
  final String uid;
  final String username;
  final String photoUrl;

  /// for requests: sent by email rather than username
  final bool byEmail;

  const FriendCard(this.uid, this.username, this.photoUrl,
      {this.byEmail = false});

  factory FriendCard.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc,
          {bool byEmail = false}) =>
      FriendCard(doc.id, doc.data()?['username'] as String? ?? '',
          doc.data()?['photoUrl'] as String? ?? '',
          byEmail: byEmail);
}

enum FriendRequestResult {
  /// a request went out
  sent,

  /// they had already asked the user, so this made them friends
  accepted,
  notFound,
  isYou,
  alreadyFriends,

  /// official accounts can't be friended
  notAllowed,
}

/// What EmailRequests ids an email by: SHA-256 hex of the trimmed,
/// lowercased address, so the database never holds the address. The rules
/// compute the same from the signed-in user's own email.
String emailHash(String email) =>
    sha256.convert(utf8.encode(email.trim().toLowerCase())).toString();

/// Looks like an email rather than a username (usernames can't hold @)
bool looksLikeEmail(String input) => input.contains('@');

CollectionReference<Map<String, dynamic>> _friends(
        FirebaseFirestore firestore, String uid) =>
    firestore.collection('Users').doc(uid).collection('Friends');

CollectionReference<Map<String, dynamic>> _requests(
        FirebaseFirestore firestore, String uid) =>
    firestore.collection('Users').doc(uid).collection('FriendRequests');

CollectionReference<Map<String, dynamic>> _emailRequests(
        FirebaseFirestore firestore, String hash) =>
    firestore.collection('EmailRequests').doc(hash).collection('From');

Map<String, dynamic> _card(DbUser me) => {
      'username': me.username ?? '',
      'photoUrl': me.profilePicture,
      'sentAt': FieldValue.serverTimestamp(),
    };

/// The user with this username (any case), or null. 2 reads.
Future<FriendCard?> findUserByUsername(
    FirebaseFirestore firestore, String username) async {
  final name = username.trim();
  if (!validUsername.hasMatch(name)) return null;
  final claim =
      await firestore.collection('Usernames').doc(usernameKey(name)).get();
  final uid = claim.data()?['uid'] as String?;
  if (uid == null) return null;
  final user = await firestore.collection('Users').doc(uid).get();
  if (!user.exists) return null;
  return FriendCard(uid, user.data()?['username'] as String? ?? name,
      user.data()?['profileImage'] as String? ?? '');
}

/// Sends a friend request by username. If they already asked the user,
/// accepts theirs instead.
Future<FriendRequestResult> sendFriendRequest(
    FirebaseFirestore firestore, DbUser me, String username) async {
  final them = await findUserByUsername(firestore, username);
  if (them == null) return FriendRequestResult.notFound;
  if (them.uid == me.uid) return FriendRequestResult.isYou;
  if (them.uid == chucklerUid) return FriendRequestResult.notAllowed;
  if ((await _friends(firestore, me.uid!).doc(them.uid).get()).exists) {
    return FriendRequestResult.alreadyFriends;
  }
  if ((await _requests(firestore, me.uid!).doc(them.uid).get()).exists) {
    await acceptFriendRequest(firestore, me, them);
    return FriendRequestResult.accepted;
  }
  await _requests(firestore, them.uid).doc(me.uid).set(_card(me));
  return FriendRequestResult.sent;
}

/// Sends a friend request to an email. It says nothing about whether an
/// account has that email: if one does, its owner sees the request.
Future<void> sendEmailFriendRequest(
    FirebaseFirestore firestore, DbUser me, String email) async {
  await _emailRequests(firestore, emailHash(email)).doc(me.uid).set(_card(me));
}

/// Requests sent to the user, by username and to their email ([myEmail]),
/// one per sender (username requests win over email ones from the same person)
Future<List<FriendCard>> getFriendRequests(
    FirebaseFirestore firestore, String uid, String? myEmail) async {
  final byName = await _requests(firestore, uid).get();
  final cards = {
    for (final d in byName.docs) d.id: FriendCard.fromDoc(d),
  };
  if (myEmail != null && myEmail.isNotEmpty) {
    final byEmail = await _emailRequests(firestore, emailHash(myEmail)).get();
    for (final d in byEmail.docs) {
      cards.putIfAbsent(d.id, () => FriendCard.fromDoc(d, byEmail: true));
    }
  }
  return cards.values.toList();
}

/// Accepts a request: both Friends docs and the request's removal, in one
/// batch. [myEmail] is needed for requests sent by email.
Future<void> acceptFriendRequest(
    FirebaseFirestore firestore, DbUser me, FriendCard them,
    {String? myEmail}) async {
  final batch = firestore.batch();
  batch.set(_friends(firestore, me.uid!).doc(them.uid), {
    'username': them.username,
    'photoUrl': them.photoUrl,
    'since': FieldValue.serverTimestamp(),
  });
  batch.set(_friends(firestore, them.uid).doc(me.uid), {
    'username': me.username ?? '',
    'photoUrl': me.profilePicture,
    'since': FieldValue.serverTimestamp(),
  });
  batch.delete(them.byEmail && myEmail != null
      ? _emailRequests(firestore, emailHash(myEmail)).doc(them.uid)
      : _requests(firestore, me.uid!).doc(them.uid));
  await batch.commit();
}

/// Declines (deletes) a request
Future<void> declineFriendRequest(
    FirebaseFirestore firestore, String myUid, FriendCard them,
    {String? myEmail}) async {
  await (them.byEmail && myEmail != null
          ? _emailRequests(firestore, emailHash(myEmail)).doc(them.uid)
          : _requests(firestore, myUid).doc(them.uid))
      .delete();
}

/// The user's friends, by username
Future<List<FriendCard>> getFriends(
    FirebaseFirestore firestore, String uid) async {
  final snap = await _friends(firestore, uid).get();
  return snap.docs.map(FriendCard.fromDoc).toList()
    ..sort((a, b) =>
        a.username.toLowerCase().compareTo(b.username.toLowerCase()));
}

/// How many friends the user has (1 read per 1,000)
Future<int> countFriends(FirebaseFirestore firestore, String uid) async {
  final agg = await _friends(firestore, uid).count().get();
  return agg.count ?? 0;
}

/// Unfriends: removes the doc on both sides
Future<void> removeFriend(
    FirebaseFirestore firestore, String myUid, String theirUid) async {
  final batch = firestore.batch();
  batch.delete(_friends(firestore, myUid).doc(theirUid));
  batch.delete(_friends(firestore, theirUid).doc(myUid));
  await batch.commit();
}

/// Legacy (Past feed popup): see the note at the top of this file.

/// ADDS a following document when a user creates a follow...This can be used bidirectionally
/// inorder to minimize both the reads and writes for document
/// Returns 0 if pending, 1 if friended, and -1 if error
Future<int> friend(
    FirebaseFirestore firestore,
    String userFriendingUid,
    String userToFriendUid,
    String friendingUsername,
    String toFriendUsername,
    List<String> friendsList,
    bool complete) async {
  List<String> u = [userFriendingUid];
  List<String> them = [userToFriendUid];
  List<String> uUsername = [friendingUsername];
  List<String> themUsername = [toFriendUsername];
  if (!complete) {
    await firestore.collection('Users').doc(userToFriendUid).update({
      'pendingFriendsList': FieldValue.arrayUnion(u),
      'pendingFriends': FieldValue.increment(1)
    });
  } else {
    DateTime now = DateTime.now().toUtc();

    final timestamp = Timestamp.fromDate(now);
    await firestore.collection('Users').doc(userFriendingUid).update({
      'pendingFriendsList': FieldValue.arrayRemove(them),
      'pendingFriends': FieldValue.increment(-1),
      'friends': FieldValue.increment(1),
      'friendsList': FieldValue.arrayUnion(themUsername)
    });
    await firestore.collection('Users').doc(userToFriendUid).update({
      'friends': FieldValue.increment(1),
      'friendsList': FieldValue.arrayUnion(uUsername)
    });
    if (friendsList.isNotEmpty) {
      await firestore.collection('Notifications').add({
        'type': 0,
        'message': '$friendingUsername and $toFriendUsername are now friends!',
        'uid1': userFriendingUid,
        'uid2': userToFriendUid,
        'date': timestamp,
        'inform': friendsList
      });
    }
  }
  return 0;
}
