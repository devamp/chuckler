import 'package:cloud_firestore/cloud_firestore.dart';

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
