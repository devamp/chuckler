import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';
import 'sample_prompts.dart';

// Who made each prompt, and prompts users write for their friends.
//
// Friend prompts are FriendPrompts/{uid}_{dayId} (one per user per prompt
// day). The creator writes one without an audience; the
// onFriendPromptCreated function sets audience to the creator and their
// friends, and only they can read it, answer it and see its matchups. It
// lives for the prompt day it was made in. See docs/data-model.md.

enum CreatorKind { user, official, sponsor }

/// The account shown as a prompt's creator, with its profile icon
class PromptCreator {
  final String uid;
  final String username;

  /// '' until profile photos are stored for the account
  final String photoUrl;
  final CreatorKind kind;

  /// public bio; only official and sponsor accounts have one here, since
  /// normal users' bios are for friends only
  final String? bio;

  const PromptCreator({
    required this.uid,
    required this.username,
    this.photoUrl = '',
    this.kind = CreatorKind.user,
    this.bio,
  });
}

const String chucklerUid = 'chuckler';

/// The official account that creates the daily prompts
const PromptCreator chuckler = PromptCreator(
  uid: chucklerUid,
  username: 'Chuckler',
  kind: CreatorKind.official,
  bio: 'Professional blank-filler. I write the prompts, you do the funny '
      'part. 🤡',
);

/// Prompts whose answers, likes and stats stay on the phone
bool isLocalPrompt(DbPrompt prompt) => isSamplePrompt(prompt);

/// A prompt a friend (or the user) wrote, from FriendPrompts
bool isFriendPrompt(DbPrompt prompt) => prompt.type == friendPromptType;

/// DbPrompt.type of friend prompts
const String friendPromptType = 'friend';

CollectionReference<Map<String, dynamic>> friendPromptsRef(
        FirebaseFirestore firestore) =>
    firestore.collection('FriendPrompts');

/// The id of [uid]'s friend prompt on prompt day [dayId]
String friendPromptId(String uid, String dayId) => '${uid}_$dayId';

/// Maps a FriendPrompts doc to a DbPrompt. Its promptDateId is the day it
/// lives on, so answers and matchups group with that day.
DbPrompt friendPromptFromDoc(String id, Map<String, dynamic> data) {
  final creator = data['creator'] as Map<String, dynamic>?;
  final counts = data['counts'] as Map<String, dynamic>?;
  final dayId = data['dayId'] as String? ?? '';
  return DbPrompt(data['before'] ?? '', data['after'] ?? '', dayId, id, dayId,
      friendPromptType)
    ..responses = (counts?['answers'] as num?)?.toInt() ?? 0
    ..location = 'friends'
    ..kind = data['kind'] ?? 'fill'
    ..creatorUid = creator?['uid']
    ..creatorUsername = creator?['username']
    ..creatorPhotoUrl = creator?['photoUrl'];
}

/// Today's friend prompts for [uid]: those whose audience includes them,
/// plus their own (read directly, in case the audience isn't set yet).
/// Oldest first, so the order stays put as new ones arrive.
Future<List<DbPrompt>> getFriendPrompts(
    FirebaseFirestore firestore, String uid, String dayId) async {
  final results = await Future.wait([
    friendPromptsRef(firestore)
        .where('audience', arrayContains: uid)
        .where('dayId', isEqualTo: dayId)
        .get()
        .then((q) => q.docs),
    friendPromptsRef(firestore).doc(friendPromptId(uid, dayId)).get().then(
        (d) => d.exists ? [d] : <DocumentSnapshot<Map<String, dynamic>>>[]),
  ]);
  final byId = <String, DocumentSnapshot<Map<String, dynamic>>>{};
  for (final list in results) {
    for (final d in list) {
      byId[d.id] = d;
    }
  }
  // hidden: taken down after reports
  final docs = byId.values
      .where((d) => d.data() != null && d.data()!['status'] != 'hidden')
      .toList()
    ..sort((a, b) {
      final ta = a.data()!['createdAt'] as Timestamp?;
      final tb = b.data()!['createdAt'] as Timestamp?;
      if (ta == null || tb == null) return a.id.compareTo(b.id);
      return ta.compareTo(tb);
    });
  return [for (final d in docs) friendPromptFromDoc(d.id, d.data()!)];
}

/// Longest text allowed on either side of the blank
const int maxPromptPartLength = 120;

/// Trims both sides and puts single spaces around the blank, except before
/// punctuation that follows it ("I love ____!" keeps the "!" attached)
(String, String) normalizePromptParts(String before, String after) {
  var b = before.trim();
  var a = after.trim();
  if (b.isNotEmpty) b = '$b ';
  if (a.isNotEmpty && RegExp(r'^[\p{L}\p{N}(]', unicode: true).hasMatch(a)) {
    a = ' $a';
  }
  return (b, a);
}

/// Writes a prompt for the user's friends on prompt day [dayId] and
/// returns it. The rules allow one per user per day (the id is
/// {uid}_{dayId}, and docs are never rewritten), so a second one throws.
Future<DbPrompt> createFriendPrompt(FirebaseFirestore firestore, DbUser user,
    String before, String after, String dayId) async {
  final (b, a) = normalizePromptParts(before, after);
  final id = friendPromptId(user.uid!, dayId);
  final creator = {
    'uid': user.uid,
    'username': user.username ?? '',
    'photoUrl': user.profilePicture,
  };
  await friendPromptsRef(firestore).doc(id).set({
    'before': b,
    'after': a,
    'kind': 'fill',
    'dayId': dayId,
    'createdAt': FieldValue.serverTimestamp(),
    'creator': creator,
    'status': 'active',
    'counts': {'answers': 0, 'likes': 0, 'dislikes': 0},
    'likedBy': [],
  });
  return friendPromptFromDoc(id, {
    'before': b,
    'after': a,
    'kind': 'fill',
    'dayId': dayId,
    'creator': creator,
  });
}
