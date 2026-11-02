import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/models.dart';
import 'dart:math';

//TODO LOOK AT IMPLEMENTING A DEBOUNCER TO PREVENT READ ABUSE

///CREATE METHODS
///
///

/// @author Caden Deutscher
/// @description - adds a comment to the subcollection 'Comments' in both the user and post objects
Future<void> addCommentToPost(FirebaseFirestore firestore, String postId,
    String usernameCommenter, String comment) async {
  DateTime now = DateTime.now().toUtc();

  final timestamp = Timestamp.fromDate(now);
  try {
    // Reference the comments subcollection within the post document
    final pCommentsRef = firestore.collection('Comments');

    // Create a new document within the comments subcollection
    await pCommentsRef.add({
      'username': usernameCommenter,
      'comment': comment,
      'postId': postId,
      'date': timestamp
    });
  } catch (e) {
    print('Error adding comment: $e');
  }
}

/// Create a new post
Future<DbPost> createPost(
    FirebaseFirestore firebase, DbUser u, DbPrompt prompt, answer) async {
  final now = DateTime.now().toUtc();
  final timestamp = Timestamp.fromDate(now);
  CollectionReference collection = firebase.collection('Posts');
  var rng = Random();
  var random1 = rng.nextInt(pow(2, 32).toInt());
  var random2 = rng.nextInt(pow(2, 32).toInt());
  var bigRandom = (random1 << 32) | random2;
  //canPost[promptVal] = false;
  String docId = "";
  await collection
      .add({
        'answer': answer,
        'dislikes': 0,
        'likes': 0,
        'wins': 0,
        'uid': u.uid,
        'username': u.username,
        'promptId': prompt.promptId,
        'random': bigRandom,
        'promptDateId': prompt.promptDateId,
        'date': timestamp
      })
      .then((docRef) => {docId = docRef.id})
      .catchError((error) => print("Failed to add data: $error"));

  DbPost posted = DbPost(docId, answer, u.username, u.uid, 0, 0, 0,
      prompt.promptId, prompt.promptDateId);
  posted.mine = true;
  return posted;
}

///READ METHODS
///
///

/// promptId and promptDateId of the placeholder prompt shown while today's
/// prompt has not been published yet
const String awaitingPromptId = 'awaiting-daily-prompt';

/// Placeholder returned by getDailyPrompts when there is no prompt for today.
/// Its date is left null so the Isar cache never serves it on a later login.
DbPrompt awaitingPrompt() {
  return DbPrompt('The daily prompt is still', 'in the oven. Check back soon!',
      awaitingPromptId, awaitingPromptId, null, null);
}

bool isAwaitingPrompt(DbPrompt prompt) {
  return prompt.promptId == awaitingPromptId;
}

/**
    @author - Caden Deutscher
    @params - firestore - firestore instance to query data from
    @return - List of prompts for today
 */
Future<List<DbPrompt>> getDailyPrompts(FirebaseFirestore firestore) async {
  List<DbPrompt> prompts = List.empty(growable: true);
  DateTime now = DateTime.now().toUtc();
  // Calculate UTC midnight
  final utcMidnight = now.subtract(Duration(
      hours: now.hour,
      minutes: now.minute,
      seconds: now.second,
      milliseconds: now.microsecond));
  // Calculate UTC 11:59 (the last second of the day before midnight)
  final utc1159 = utcMidnight.add(const Duration(days: 1, seconds: -1));

  print("UTC Midnight: $utcMidnight");
  print("UTC 11:59: $utc1159");
  DateTime today = DateTime(now.year, now.month, now.day);
  // Create timestamps for the start and end dates
  Timestamp startDate = Timestamp.fromDate(utcMidnight);
  Timestamp endDate = Timestamp.fromDate(utc1159);
  QuerySnapshot querySnapshot = await firestore
      .collection('PromptDays')
      .where('date', isGreaterThanOrEqualTo: startDate)
      .where('date', isLessThan: endDate)
      .get();

  if (querySnapshot.docs.isEmpty) {
    print("NO DOCS FOUND FOR TODAY $startDate");
  } else {
    String pid = querySnapshot.docs.first.id;
    print("this is the pid$pid");
    CollectionReference cr =
        querySnapshot.docs.first.reference.collection("Prompts");
    final gs = await cr.get();
    if (gs.docs.isNotEmpty) {
      for (QueryDocumentSnapshot ds in gs.docs) {
        Map<String, dynamic> data = ds.data() as Map<String, dynamic>;
        dynamic before = data['before'];
        dynamic after = data['after'];
        dynamic type = data['type'];
        DbPrompt toAdd = DbPrompt(before, after, pid, ds.id,
            utcMidnight.toIso8601String().substring(0, 10), type);
        try{
          toAdd.responses = data['responses'];
        }
        catch(e){
          print(e);
        }
        prompts.add(toAdd);
      }

    }
  }
  if (prompts.isEmpty) {
    prompts.add(awaitingPrompt());
  }
  return prompts;
}

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

/// Description: Get the 10 posts from the database...put them in the
Future<List<DbPost>> getPosts(
    FirebaseFirestore firestore, String prmtId, String prmtDateId) async {
  print("specs");
  print(prmtId);
  print(prmtDateId);
  final prefs = await SharedPreferences.getInstance();
  String? loginTime = prefs.getString('lastLoginTime');
  DateTime lastDate;
  if (loginTime == null) {
    lastDate = DateTime(1990);
  } else {
    lastDate = DateTime.parse(loginTime);
  }

//Query
  QuerySnapshot querySnapshot = await firestore
      .collection('Posts')
      .where('promptId', isEqualTo: prmtId)
      .where('promptDateId', isEqualTo: prmtDateId)
      .where('date', isGreaterThanOrEqualTo: lastDate)
      .limit(10)
      .get();
  if (querySnapshot.docs.isEmpty) {
    querySnapshot = await firestore
        .collection('Posts')
        .where('promptId', isEqualTo: prmtId)
        .where('promptDateId', isEqualTo: prmtDateId)
        .limit(10)
        .get();
  }

//create the postList
  List<DbPost> toReturn = List<DbPost>.empty(growable: true);
  if (querySnapshot.docs.isEmpty) {
    print("STILL EMPTY");
    return toReturn;
  } else {
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      dynamic answer = data['answer'];
      dynamic username = data['username'];
      dynamic likes = data['likes'];
      dynamic dislikes = data['dislikes'];
      dynamic wins = data['wins'];
      dynamic uid = data['uid'];
      toReturn.add(DbPost(doc.id, answer, username, uid, likes, dislikes, wins,
          prmtId, prmtDateId));
    }
    return toReturn;
  }
}

/// Description: Get the first few comments from a post
Future<List<DbComment>> getComments(
    FirebaseFirestore firestore, String postId) async {
  List<DbComment> comments = List<DbComment>.empty(growable: true);
  try {
    QuerySnapshot querySnapshot = await firestore
        .collection('Comments')
        .where('postId', isEqualTo: postId)
        .limit(5)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("STILL EMPTY");
      return comments;
    } else {
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        dynamic comment = data['comment'];
        dynamic username = data['username'];
        comments.add(DbComment(username, comment));
      }
    }
  } catch (error) {}
  return comments;
}
/**
 * Check if there is a document created by a user for a specific prompt/prompt date
 * Return null if there is not a doc
 */
Future<DbPost?> getUserPostForPrompt(FirebaseFirestore firestore, String uid,
    String promptDateId, String promptId) async {
  try {
    var docRef = await firestore
        .collection('Posts')
        .where('promptDateId', isEqualTo: promptDateId)
        .where('promptId', isEqualTo: promptId)
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();
    var docData = docRef.docs.first.data();
    if(docRef.docs.isEmpty){
      return null;
    }
    return DbPost(
        docRef.docs.first.id,
        docData['answer'],
        docData['username'],
        docData['uid'],
        docData['likes'],
        docData['dislikes'],
        docData['wins'],
        promptId,
        promptDateId);
  } catch (e) {
    return null;
  }
}

///UPDATE METHODS
///
///

/// Description increment user number of posts
Future<void> incrementNumPosts(FirebaseFirestore firestore, String uid) async {
  firestore
      .collection('Users')
      .doc(uid)
      .update({'posts': FieldValue.increment(1)});
}

/**
    When liking a post we will create a like-relationship document, and incrament the posts number of likes
 */
Future<void> likeAPost(FirebaseFirestore firestore, String likerUid,
    String postId, String postOwnerUid) async {
  DateTime now = DateTime.now().toUtc();

  final timestamp = Timestamp.fromDate(now);
  try {
    firestore.collection("Notifications").doc().set({
      'type': "like",
      'postId': postId,
      'liker': likerUid,
      'date': timestamp,
      'notify': [postOwnerUid]
    });
    firestore
        .collection("Posts")
        .doc(postId)
        .update({'likes': FieldValue.increment(1)});
  } catch (e) {
    print('Error adding comment: $e');
  }
}

/// To keep track of wins we will simply increment that value in posts
Future<void> postWin(FirebaseFirestore firestore, String postId) async {
  try {
    await firestore
        .collection("Posts")
        .doc(postId)
        .update({'wins': FieldValue.increment(1)});
  } catch (e) {
    print('Error adding comment: $e');
  }
}

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

///Updates the profile photo url for a user
Future<void> updateProfilePhoto(
    FirebaseFirestore firestore, String url, String uid) async {
  await firestore.collection("Users").doc(uid).update({'profileImage': url});
}
