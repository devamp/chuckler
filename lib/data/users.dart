import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';

//TODO LOOK AT IMPLEMENTING A DEBOUNCER TO PREVENT READ ABUSE

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
  firestore
      .collection('Users')
      .doc(uid)
      .update({'posts': FieldValue.increment(1)});
}

///Updates the profile photo url for a user
Future<void> updateProfilePhoto(
    FirebaseFirestore firestore, String url, String uid) async {
  await firestore.collection("Users").doc(uid).update({'profileImage': url});
}
