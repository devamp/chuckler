import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';

//TODO LOOK AT IMPLEMENTING A DEBOUNCER TO PREVENT READ ABUSE

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
  final utcMidnight = DateTime.utc(now.year, now.month, now.day);
  // Calculate the next UTC midnight (the query excludes it)
  final nextMidnight = utcMidnight.add(const Duration(days: 1));

  print("UTC Midnight: $utcMidnight");
  print("Next UTC Midnight: $nextMidnight");
  DateTime today = DateTime(now.year, now.month, now.day);
  // Create timestamps for the start and end dates
  Timestamp startDate = Timestamp.fromDate(utcMidnight);
  Timestamp endDate = Timestamp.fromDate(nextMidnight);
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
