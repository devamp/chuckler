import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../data/prompt_day.dart';
import 'models.dart';

class IsarService {
  static late Isar db;

  static Future<void> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      db = await Isar.open(
        [
          DbPostSchema,
          DbPromptSchema,
          DbUserSchema,
          DbCommentSchema,
          DbNotificationSchema
        ], // Here we will add a schema's
        directory: dir.path,
        inspector: true,
      );
    }

    db = await Future.value(Isar.getInstance());
  }

  /// Empties the on-device cache, so the next account to sign in on this
  /// phone doesn't see the last one's answers
  Future<void> clearAll() async {
    await db.writeTxn(() async {
      await db.clear();
    });
  }

  /// CREATE FUNCTIONS

  Future<void> addUserToDb(DbUser user) async {
    await db.writeTxn(() async {
      await db.dbUsers.put(user);
    });
  }

  //Adds a list of posts to the database
  Future<void> addPostsToDB(List<DbPost> posts) async {
    await db.writeTxn(() async {
      await db.dbPosts.putAll(posts);
    });
  }

  //Adds a list of prompts to the database
  Future<void> addPromptsToDB(List<DbPrompt> prompts) async {
    for (DbPrompt prompt in prompts) {
      DbPrompt? p = await db.dbPrompts
          .filter()
          .promptDateIdEqualTo(prompt.promptDateId)
          .and()
          .promptIdEqualTo(prompt.promptId)
          .findFirst();
      if (p != null) {
        //Update appropriately
      } else {
        await db.writeTxn(() async {
          await db.dbPrompts.put(prompt);
        });
      }
    }
  }

  //Adds one post to the database
  Future<void> addOnePostToDB(DbPost post) async {
    await db.writeTxn(() async {
      await db.dbPosts.put(post);
    });
  }

  //Adds one prompt to the database
  Future<void> addOnePromptToDB(DbPrompt prompt) async {
    await db.writeTxn(() async {
      await db.dbPrompts.put(prompt);
    });
  }

  ///READ FUNCTIONS
  //Get a list of all the posts that the user has not seen
  Future<List<DbPost>> getUnseenPosts() async {
    final posts = await db.dbPosts.filter().seenEqualTo(false).findAll();
    return posts;
  }

  Future<List<DbPrompt>> getDailyPromptsFromDB() async {
    final dayId = promptDayId(DateTime.now().toUtc());
    // promptDateId is the day id in the current layout, which leaves out
    // prompts cached under the old layout's random PromptDays ids
    final prompts = await db.dbPrompts
        .filter()
        .dateEqualTo(dayId)
        .promptDateIdEqualTo(dayId)
        .findAll();
    return prompts;
  }

  ///Gets the logged in users posts
  Future<List<DbPost>> getLoggedInUserPostsDB() async {
    List<DbPost> userPosts = List.empty(growable: true);
    userPosts = await db.dbPosts.filter().mineEqualTo(true).findAll();
    return userPosts;
  }

  ///Get a prompt based on information from a pust
  Future<DbPrompt?> getASpecificPromptDB(
      String prmptId, String prmptDateId) async {
    return await db.dbPrompts
        .filter()
        .promptIdEqualTo(prmptId)
        .and()
        .promptDateIdEqualTo(prmptDateId)
        .findFirst();
  }

  ///Get a user from the database with uid = to the provided one
  Future<DbUser?> getUserFromDb(String userid) async {
    try {
      return await db.dbUsers.filter().uidEqualTo(userid).findFirst();
    } catch (error) {
      return null;
    }
  }

  ///UPDATE FUNCTIONS
  //Get two unseen posts and set the values to seen
  Future<List<DbPost>> getTwoUnseenPosts() async {
    final posts =
        await db.dbPosts.filter().seenEqualTo(false).limit(2).findAll();
    for (DbPost p in posts) {
      p.seen = true;
    }
    await db.writeTxn(() async {
      await db.dbPosts.putAll(posts);
    });

    return posts;
  }

  ///DELETE FUNCTIONS

  //Deletes all posts that have been seen already
  Future<void> deleteSeenPosts() async {
    await db.dbPosts.filter().seenEqualTo(true).deleteAll();
  }
}
