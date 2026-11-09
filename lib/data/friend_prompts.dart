import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';
import 'sample_prompts.dart';

// Who made each prompt, and prompts users write for their friends. Friend
// prompts stay on the phone for now; the TODO(cloud) notes and
// docs/data-model.md (FriendPrompts, Official accounts) describe the real
// collection.
//
// TODO(cloud): load the user's friend prompts with
//   FriendPrompts where audience array-contains uid and status == 'active'
// (one read per active friend prompt) and add them to the Create tab after
// the daily prompts. Each doc carries creator: {uid, username, photoUrl}.

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

/// promptDateId of friend prompts made on this phone. They never leave it
/// until FriendPrompts exists, so answers to them stay local too.
const String localFriendPromptDayId = 'friend-local';

/// Prompts whose answers, likes and stats stay on the phone
bool isLocalPrompt(DbPrompt prompt) =>
    isSamplePrompt(prompt) || prompt.promptDateId == localFriendPromptDayId;

bool isLocalFriendPrompt(DbPrompt prompt) =>
    prompt.promptDateId == localFriendPromptDayId;

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

/// Creates a prompt for the user's friends and returns it
Future<DbPrompt> createFriendPrompt(FirebaseFirestore firestore, DbUser user,
    String before, String after) async {
  // TODO(cloud): add FriendPrompts/{id} with {before, after, createdAt,
  //   creator: {uid, username, photoUrl}, status: 'active', counts: {}, likedBy: []}
  //   and no audience. A Cloud Function fills audience from the creator's
  //   Users/{uid}/Friends, since rules can't check a list of friends.
  //   Rules: creator.uid == request.auth.uid, no audience on create, and at
  //   most one friend prompt per user per day (keep a lastFriendPromptDay on
  //   Users/{uid}/Private/account, checked with getAfter).
  final (b, a) = normalizePromptParts(before, after);
  return DbPrompt(b, a, localFriendPromptDayId,
      'friend-${DateTime.now().microsecondsSinceEpoch}', null, 'friends');
}
