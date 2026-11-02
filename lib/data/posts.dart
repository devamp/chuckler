import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/models.dart';
import 'dart:math';

//TODO LOOK AT IMPLEMENTING A DEBOUNCER TO PREVENT READ ABUSE

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
