import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/models.dart';
import 'prompt_day.dart';

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

/// Today's prompts: PromptDays/{dayId} and its Prompts (1 + N reads).
/// Returns the awaiting placeholder when today has no prompts yet.
Future<List<DbPrompt>> getDailyPrompts(FirebaseFirestore firestore,
    {DateTime? now}) async {
  final dayId = promptDayId(now ?? DateTime.now().toUtc());
  List<DbPrompt> prompts = List.empty(growable: true);
  final day = firestore.collection('PromptDays').doc(dayId);
  final snapshot = await day.collection('Prompts').get();
  for (final doc in snapshot.docs) {
    prompts.add(promptFromDoc(dayId, doc.id, doc.data()));
  }
  if (prompts.isEmpty) {
    prompts.add(awaitingPrompt());
  }
  return prompts;
}

/// Maps a PromptDays/{dayId}/Prompts/{id} doc to a DbPrompt
DbPrompt promptFromDoc(String dayId, String id, Map<String, dynamic> data) {
  final creator = data['creator'] as Map<String, dynamic>?;
  final counts = data['counts'] as Map<String, dynamic>?;
  return DbPrompt(data['before'] ?? '', data['after'] ?? '', dayId, id, dayId,
      data['type'])
    ..responses = (counts?['answers'] as num?)?.toInt() ?? 0
    ..location = data['location']
    ..kind = data['kind'] ?? 'fill'
    ..creatorUid = creator?['uid']
    ..creatorUsername = creator?['username']
    ..creatorPhotoUrl = creator?['photoUrl'];
}
