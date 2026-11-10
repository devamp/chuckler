import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show AssetBundle, rootBundle;

// Moderation (App Store guideline 1.2): reporting content and people,
// blocking people, and a word filter on what users write. The server side
// (counting reports, hiding content, unfriending on block) is in
// functions/moderation.js. See docs/data-model.md.

/// Why something was reported. The names are what the rules accept.
enum ReportReason {
  offensive('Offensive or hateful'),
  harassment('Harassment or bullying'),
  sexual('Sexual content'),
  spam('Spam'),
  other('Something else');

  final String label;
  const ReportReason(this.label);
}

/// What was reported
enum ReportTarget { answer, comment, prompt, user }

// ---- Word filter --------------------------------------------------------

const String wordListAsset = 'functions/wordlist.json';

const Map<String, String> _swaps = {
  '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's', '@': 'a', r'$': 's', //
};

/// One category of the word list, which viewers can filter out
class WordCategory {
  final String id;
  final String label;
  final bool defaultOn;
  final Set<String> words;

  const WordCategory(this.id, this.label, this.defaultOn, this.words);
}

/// The categories in a word list file (functions/wordlist.json), in order
List<WordCategory> parseWordList(String json) {
  final cats = (jsonDecode(json) as Map)['categories'] as Map;
  return [
    for (final e in cats.entries)
      WordCategory(
          e.key as String,
          (e.value as Map)['label'] as String? ?? e.key as String,
          (e.value as Map)['defaultOn'] == true,
          {...(((e.value as Map)['words'] as List?) ?? const [])
              .whereType<String>()}),
  ];
}

Future<List<WordCategory>> loadWordList([AssetBundle? bundle]) async =>
    parseWordList(await (bundle ?? rootBundle).loadString(wordListAsset));

/// Every word in [categories] (all of them for usernames)
Set<String> wordsIn(Iterable<WordCategory> categories) =>
    {for (final c in categories) ...c.words};

/// The categories a new account filters out
Set<String> defaultContentFilter(List<WordCategory> categories) =>
    {for (final c in categories) if (c.defaultOn) c.id};

/// Whether [text] holds a word from [words]: whole words after lowercasing
/// and undoing common letter swaps, with a trailing s/es/ed/ing allowed,
/// so "class" or "Scunthorpe" don't match. The twin of
/// containsBlockedWords in functions/moderation.js.
bool containsBlockedWords(String text, Set<String> words) {
  if (words.isEmpty) return false;
  final swapped = text
      .toLowerCase()
      .replaceAllMapped(RegExp(r'[01345@$]'), (m) => _swaps[m[0]]!);
  final list = swapped.split(RegExp('[^a-z]+')).where((w) => w.isNotEmpty);
  // words split by spaces, e.g. "k y s", also checked joined up
  final joined = list.where((w) => w.length == 1).join();
  for (final w in [...list, joined]) {
    if (w.isEmpty) continue;
    if (words.contains(w)) return true;
    for (final end in const ['s', 'es', 'ed', 'ing']) {
      if (w.endsWith(end) &&
          words.contains(w.substring(0, w.length - end.length))) {
        return true;
      }
    }
  }
  return false;
}

/// What signup says about a username with a listed word
const String blockedUsernameMessage =
    "That username has language we don't allow.";

// ---- Content filter setting ----------------------------------------------

/// The categories the user hides (Private/settings `contentFilter`), or
/// null if they never chose (then the defaults apply)
Future<Set<String>?> getContentFilter(
    FirebaseFirestore firestore, String uid) async {
  final data = (await firestore
          .collection('Users')
          .doc(uid)
          .collection('Private')
          .doc('settings')
          .get())
      .data();
  final list = data?['contentFilter'] as List?;
  return list == null ? null : {...list.whereType<String>()};
}

Future<void> saveContentFilter(
        FirebaseFirestore firestore, String uid, Set<String> ids) =>
    firestore
        .collection('Users')
        .doc(uid)
        .collection('Private')
        .doc('settings')
        .set({'contentFilter': ids.toList()..sort()}, SetOptions(merge: true));

// ---- Reports ------------------------------------------------------------

DocumentReference<Map<String, dynamic>> _private(
        FirebaseFirestore firestore, String uid, String doc) =>
    firestore.collection('Users').doc(uid).collection('Private').doc(doc);

/// Reports something, and remembers it in Private/reported so it's hidden
/// for the reporter right away. [targetId] is the post id for an answer,
/// the comment id, the friend prompt id or the person's uid.
Future<void> reportContent(
  FirebaseFirestore firestore, {
  required String reporter,
  required ReportTarget target,
  required String targetId,
  required ReportReason reason,
  String? postId,
  String? matchupId,
  String? note,
}) async {
  final batch = firestore.batch();
  batch.set(firestore.collection('Reports').doc(), {
    'reporter': reporter,
    'targetType': target.name,
    'targetId': targetId,
    if (postId != null) 'postId': postId,
    if (matchupId != null) 'matchupId': matchupId,
    if (target == ReportTarget.comment) 'commentId': targetId,
    'reason': reason.name,
    if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    'at': FieldValue.serverTimestamp(),
  });
  final hide = switch (target) {
    ReportTarget.answer => matchupId == null
        ? null
        : {'matchupIds': FieldValue.arrayUnion([matchupId])},
    ReportTarget.comment => {
        'commentIds': FieldValue.arrayUnion([targetId])
      },
    ReportTarget.prompt => {
        'promptIds': FieldValue.arrayUnion([targetId])
      },
    ReportTarget.user => null,
  };
  if (hide != null) {
    batch.set(_private(firestore, reporter, 'reported'), hide,
        SetOptions(merge: true));
  }
  await batch.commit();
}

// ---- Blocking -----------------------------------------------------------

/// Someone the user blocked
class BlockedUser {
  final String uid;
  final String username;
  final String photoUrl;

  const BlockedUser(this.uid, this.username, [this.photoUrl = '']);
}

CollectionReference<Map<String, dynamic>> _blocked(
        FirebaseFirestore firestore, String uid) =>
    firestore.collection('Users').doc(uid).collection('Blocked');

/// Blocks [them]. onBlockCreated then unfriends them, removes requests and
/// keeps their matchups out of the user's queue. They aren't told.
Future<void> blockUser(
        FirebaseFirestore firestore, String me, BlockedUser them) =>
    _blocked(firestore, me).doc(them.uid).set({
      'uid': them.uid,
      'username': them.username,
      'photoUrl': them.photoUrl,
      'at': FieldValue.serverTimestamp(),
    });

/// Unblocks [uid]. Friendship isn't restored; they can be added again.
Future<void> unblockUser(FirebaseFirestore firestore, String me, String uid) =>
    _blocked(firestore, me).doc(uid).delete();

Future<List<BlockedUser>> getBlocked(
    FirebaseFirestore firestore, String me) async {
  final snap = await _blocked(firestore, me).get();
  return [
    for (final d in snap.docs)
      BlockedUser(d.id, d.data()['username'] as String? ?? '',
          d.data()['photoUrl'] as String? ?? ''),
  ]..sort((a, b) =>
      a.username.toLowerCase().compareTo(b.username.toLowerCase()));
}

/// The user's uid for [username], or null (one read)
Future<String?> uidForUsername(
    FirebaseFirestore firestore, String username) async {
  final claim = await firestore
      .collection('Usernames')
      .doc(username.trim().toLowerCase())
      .get();
  return claim.data()?['uid'] as String?;
}

/// The username for [uid], or null (one read)
Future<String?> usernameForUid(FirebaseFirestore firestore, String uid) async {
  final user = await firestore.collection('Users').doc(uid).get();
  return user.data()?['username'] as String?;
}

// ---- What to hide -------------------------------------------------------

/// Everything the user shouldn't see: people they blocked, what they
/// reported, and blocked users' matchups (kept by the server)
class ModerationState {
  final List<BlockedUser> blocked;
  final Set<String> reportedMatchups;
  final Set<String> reportedComments;
  final Set<String> reportedPrompts;
  final Set<String> blockedMatchups;

  const ModerationState({
    this.blocked = const [],
    this.reportedMatchups = const {},
    this.reportedComments = const {},
    this.reportedPrompts = const {},
    this.blockedMatchups = const {},
  });
}

Set<String> _ids(Map<String, dynamic>? data, String key) =>
    {...((data?[key] as List?) ?? const []).whereType<String>()};

/// Three reads: the Blocked list, Private/reported and
/// Private/blockedContent
Future<ModerationState> getModerationState(
    FirebaseFirestore firestore, String uid) async {
  final results = await Future.wait([
    getBlocked(firestore, uid),
    _private(firestore, uid, 'reported').get(),
    _private(firestore, uid, 'blockedContent').get(),
  ]);
  final reported =
      (results[1] as DocumentSnapshot<Map<String, dynamic>>).data();
  final content = (results[2] as DocumentSnapshot<Map<String, dynamic>>).data();
  return ModerationState(
    blocked: results[0] as List<BlockedUser>,
    reportedMatchups: _ids(reported, 'matchupIds'),
    reportedComments: _ids(reported, 'commentIds'),
    reportedPrompts: _ids(reported, 'promptIds'),
    blockedMatchups: _ids(content, 'matchupIds'),
  );
}
