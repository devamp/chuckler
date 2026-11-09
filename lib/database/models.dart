import 'package:isar_community/isar.dart';

part 'models.g.dart';

@Collection()
class DbPost {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? postId;
  String? answer;
  String? username;
  int? wins;
  int? likes;
  int? dislikes;
  String? uid;
  bool seen = false;
  bool mine = false;
  String? promptId;
  String? promptDateId;

  DbPost(this.postId, this.answer, this.username, this.uid, this.likes,
      this.dislikes, this.wins, this.promptId, this.promptDateId);
}

@Collection()
class DbPrompt {
  Id id = Isar.autoIncrement;
  String? before;
  String? after;
  String? promptDateId;
  String? promptId;
  String? date;
  String? type;
  int responses = 0;

  /// segment: 'global', 'local' or 'friends'
  String? location;

  /// prompt format: 'fill' (fill in the blank); 'caption' comes later
  String? kind;

  /// who made the prompt; null means the Chuckler account
  String? creatorUid;
  String? creatorUsername;
  String? creatorPhotoUrl;

  //If liked is 0 no selection -1 is for dislike 1 is for a like
  int liked = 0;

  DbPrompt(this.before, this.after, this.promptDateId, this.promptId, this.date,
      this.type);
}

@Collection()
class DbUser {
  Id id = Isar.autoIncrement;
  @Index(unique: true, replace: true)
  String? username;
  int? numFriends;
  int? numPosts;
  int? numPendingFriends;
  bool friend = false;
  bool isCurrentUser = false;
  bool pendingFriend = false;
  String profilePicture = "";
  @Index(unique: true, replace: true)
  String? uid;
  List<String> friends = List.empty(growable: true);
  List<String> pendingFriends = List.empty(growable: true);

  DbUser(this.uid, this.username, this.numFriends, this.numPosts,
      this.profilePicture);
}

@Collection()
class DbComment {
  Id id = Isar.autoIncrement;
  String? username;
  String? comment;

  DbComment(this.username, this.comment);
}

//TODO IMPLEMENT NOTIFICATIONS
/// HOW will this work? When a user performs an action that involves another user...Have google cloud functions
/// send a notfication to the User that is the target of the request...This could be liking posts/friend requests...etc
@Collection()
class DbNotification {
  Id id = Isar.autoIncrement;
  String? notification;
  String? by;
  String? day;
  bool seen = false;

  DbNotification(this.notification, this.by, this.day);
}
