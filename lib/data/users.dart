import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';

/// Description Retrieve logged in user information
Future<DbUser?> getLoggedInUserInfo(
    FirebaseFirestore firestore, String uid) async {
  try {
    DocumentSnapshot doc = await firestore.collection("Users").doc(uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    dynamic posts = data['posts'];
    dynamic friends = data['friends'];
    dynamic username = data['username'];
    dynamic profilePicture = data['profileImage'];
    dynamic pendingFriends = data['pendingFriends'];
    List<String> friendsList = List.empty(growable: true);
    List<String> pendingFriendsList = List.empty(growable: true);
    if (friends > 0) {
      for (dynamic x in data['friendsList']) {
        friendsList.add(x.toString());
      }
    }
    if (pendingFriends > 0) {
      if (data.containsKey("pendingFriendsList")) {
        for (dynamic x in data['pendingFriendsList']) {
          pendingFriendsList.add(x.toString());
        }
      }
      // pendingFriendsList = data['pendingFriendsList'];
    }
    DbUser theUser = DbUser(uid, username, friends, posts, profilePicture);
    theUser.friends = friendsList;
    theUser.pendingFriends = pendingFriendsList;
    theUser.numPendingFriends = pendingFriends;
    return theUser;
  } catch (error) {
    print("Error $error");
    return null;
  }
}

///
Future<DbUser?> getAUser(FirebaseFirestore firebase, String uid) async {
  try {
    DocumentSnapshot doc = await firebase.collection("Users").doc(uid).get();
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    dynamic posts = data['posts'];
    dynamic friends = data['friends'];
    dynamic username = data['username'];
    dynamic profilePicture = data['profileImage'];
    dynamic pendingFriends = data['pendingFriends'];
    DbUser theUser = DbUser(uid, username, friends, posts, profilePicture);
    if (pendingFriends > 0) {
      theUser.pendingFriends = data['pendingFriendsList'];
    }
    return theUser;
  } catch (error) {
    print("Error $error");
    return null;
  }
}

/// Description increment user number of posts
Future<void> incrementNumPosts(FirebaseFirestore firestore, String uid) async {
  await firestore
      .collection('Users')
      .doc(uid)
      .update({'posts': FieldValue.increment(1)});
}

///Updates the profile photo url for a user
Future<void> updateProfilePhoto(
    FirebaseFirestore firestore, String url, String uid) async {
  await firestore.collection("Users").doc(uid).update({'profileImage': url});
}

/// Thrown by registerNewUser when someone already has the username
class UsernameTakenException implements Exception {
  final String username;
  const UsernameTakenException(this.username);

  @override
  String toString() => 'The username "$username" is taken.';
}

/// Letters, numbers, dots and underscores, 3 to 20 long
final RegExp validUsername = RegExp(r'^[A-Za-z0-9_.]{3,20}$');

/// Usernames are unique ignoring case
String usernameKey(String username) => username.toLowerCase();

/// Creates a new user's documents in one transaction, claiming
/// Usernames/{username} so no two users share a name:
///   - Users/{uid}: public profile, plus the legacy fields other screens
///     still read (until friends move to uids)
///   - Users/{uid}/FriendView/profile: bio, stats, streak (friends only)
///   - Users/{uid}/Private/account: age (only the user)
/// Throws UsernameTakenException if the name is already claimed.
Future<void> registerNewUser(FirebaseFirestore firestore, String uid,
    String username, int age) async {
  final user = firestore.collection('Users').doc(uid);
  final name = firestore.collection('Usernames').doc(usernameKey(username));
  await firestore.runTransaction((tx) async {
    if ((await tx.get(name)).exists) {
      throw UsernameTakenException(username);
    }
    tx.set(name, {'uid': uid});
    tx.set(user, {
      'username': username,
      'profileImage': '',
      'friends': 0,
      'pendingFriends': 0,
      'posts': 0,
    });
    tx.set(user.collection('FriendView').doc('profile'), {
      'bio': '',
      'stats': {'answers': 0},
    });
    tx.set(user.collection('Private').doc('account'), {'age': age});
  });
}
