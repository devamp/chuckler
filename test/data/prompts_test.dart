// Characterization tests for lib/data/prompts.dart.
//
// These describe what the queries do today. Where today's behavior looks
// like a bug, the test still matches it and carries a TODO so the bug can be
// fixed deliberately later.

import 'package:chuckler/data/prompt_day.dart';
import 'package:chuckler/data/prompts.dart';
import 'package:chuckler/database/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    SharedPreferences.setMockInitialValues({});
  });

  group('getDailyPrompts', () {
    // 15:00 UTC on Nov 8 falls in prompt day 2026-11-08
    final now = DateTime.utc(2026, 11, 8, 15);
    const todayId = '2026-11-08';

    CollectionReference<Map<String, dynamic>> promptsOn(String dayId) =>
        firestore.collection('PromptDays').doc(dayId).collection('Prompts');

    test('maps today\'s prompts from PromptDays/{dayId}/Prompts', () async {
      await promptsOn(todayId).doc('p1').set({
        'before': 'I like',
        'after': 'a lot',
        'kind': 'fill',
        'location': 'local',
        'creator': {
          'uid': 'chuckler',
          'username': 'Chuckler',
          'photoUrl': '',
          'kind': 'official'
        },
        'counts': {'answers': 4, 'likes': 2},
      });

      final prompts = await getDailyPrompts(firestore, now: now);

      expect(prompts, hasLength(1));
      final p = prompts.single;
      expect(p.before, 'I like');
      expect(p.after, 'a lot');
      expect(p.kind, 'fill');
      expect(p.location, 'local');
      expect(p.creatorUid, 'chuckler');
      expect(p.creatorUsername, 'Chuckler');
      expect(p.responses, 4);
      expect(p.promptId, 'p1');
      // promptDateId and date are both the day id
      expect(p.promptDateId, todayId);
      expect(p.date, todayId);
      expect(isAwaitingPrompt(p), isFalse);
    });

    test('missing counts, kind and creator get defaults', () async {
      await promptsOn(todayId).doc('p1').set({'before': 'a', 'after': 'b'});

      final p = (await getDailyPrompts(firestore, now: now)).single;

      expect(p.responses, 0);
      expect(p.kind, 'fill');
      expect(p.creatorUid, isNull);
    });

    test('ignores other days', () async {
      await promptsOn('2026-11-07').doc('old').set({'before': 'a'});
      await promptsOn('2026-11-09').doc('new').set({'before': 'a'});

      final prompts = await getDailyPrompts(firestore, now: now);

      expect(prompts.single.promptId, awaitingPromptId);
    });

    test('returns the awaiting placeholder when today has no prompts',
        () async {
      final prompts = await getDailyPrompts(firestore, now: now);

      expect(prompts, hasLength(1));
      final p = prompts.single;
      expect(isAwaitingPrompt(p), isTrue);
      expect(p.promptId, awaitingPromptId);
      expect(p.promptDateId, awaitingPromptId);
      expect(p.before, 'The daily prompt is still');
      expect(p.after, 'in the oven. Check back soon!');
      expect(p.responses, 0);
      // null date keeps IsarService.getDailyPromptsFromDB from serving it
      expect(p.date, isNull);
    });

    test('before 05:00 UTC it is still the previous prompt day', () async {
      await promptsOn('2026-11-07').doc('late').set({'before': 'a'});

      final prompts = await getDailyPrompts(firestore,
          now: DateTime.utc(2026, 11, 8, 4, 59));

      expect(prompts.single.promptId, 'late');
    });
  });

  group('prompt days', () {
    test('roll over at 05:00 UTC', () {
      expect(promptDayId(DateTime.utc(2026, 11, 8, 4, 59, 59)), '2026-11-07');
      expect(promptDayId(DateTime.utc(2026, 11, 8, 5)), '2026-11-08');
      expect(promptDayId(DateTime.utc(2026, 11, 9, 4, 59)), '2026-11-08');
      expect(promptDayId(DateTime.utc(2027, 1, 1, 3)), '2026-12-31');
    });

    test('start, end, and History month', () {
      expect(promptDayStart('2026-11-08'), DateTime.utc(2026, 11, 8, 5));
      expect(promptDayEnd('2026-11-08'), DateTime.utc(2026, 11, 9, 5));
      expect(promptDayDate('2026-11-08'), DateTime.utc(2026, 11, 8));
      expect(historyMonthId('2026-11-08'), '2026-11');
    });
  });

  group('awaiting prompt helpers', () {
    // the Create page refuses to post for this prompt, so nothing is
    // posted until today's prompt exists.
    test('isAwaitingPrompt only matches the placeholder', () {
      expect(isAwaitingPrompt(awaitingPrompt()), isTrue);
      expect(isAwaitingPrompt(DbPrompt('a', 'b', 'day1', 'p1', '2026-11-01', 't')),
          isFalse);
    });
  });
}
