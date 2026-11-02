// Characterization tests for lib/data/prompts.dart.
//
// These describe what the queries do today, not what they should do. Where
// today's behavior looks like a bug, the test still matches it and carries a
// TODO so the bug can be fixed deliberately later.

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
    final now = DateTime.now().toUtc();
    final todayNoon = DateTime.utc(now.year, now.month, now.day, 12);
    final todayId = todayNoon.toIso8601String().substring(0, 10);
    final yesterdayId = todayNoon
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    Future<DocumentReference> seedPromptDay(DateTime date) {
      return firestore
          .collection('PromptDays')
          .add({'date': Timestamp.fromDate(date)});
    }

    test('maps today\'s prompts from the Prompts subcollection', () async {
      final day = await seedPromptDay(todayNoon);
      await day.collection('Prompts').doc('p1').set(
          {'before': 'I like', 'after': 'a lot', 'type': 'fun', 'responses': 4});

      final prompts = await getDailyPrompts(firestore);

      expect(prompts, hasLength(1));
      final p = prompts.single;
      expect(p.before, 'I like');
      expect(p.after, 'a lot');
      expect(p.type, 'fun');
      expect(p.responses, 4);
      expect(p.promptId, 'p1');
      // promptDateId is the PromptDays document id
      expect(p.promptDateId, day.id);
      // TODO(bug): utcMidnight subtracts now.microsecond as milliseconds.
      // Whenever the microsecond part is larger than the millisecond part
      // (about half the time), "midnight" lands in the last second of the
      // previous day and date comes out as yesterday.
      expect(p.date, anyOf(todayId, yesterdayId));
      expect(isAwaitingPrompt(p), isFalse);
    });

    test('responses defaults to 0 when the field is missing', () async {
      final day = await seedPromptDay(todayNoon);
      await day
          .collection('Prompts')
          .doc('p1')
          .set({'before': 'a', 'after': 'b', 'type': 't'});

      final prompts = await getDailyPrompts(firestore);

      expect(prompts.single.responses, 0);
    });

    test('ignores PromptDays from other days', () async {
      final yesterday = await seedPromptDay(
          todayNoon.subtract(const Duration(days: 1)));
      await yesterday
          .collection('Prompts')
          .doc('old')
          .set({'before': 'a', 'after': 'b', 'type': 't'});

      final prompts = await getDailyPrompts(firestore);

      expect(prompts.single.promptId, awaitingPromptId);
    });

    test('returns the awaiting placeholder when there is no PromptDays doc',
        () async {
      final prompts = await getDailyPrompts(firestore);

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

    test('returns the awaiting placeholder when today has no prompts',
        () async {
      await seedPromptDay(todayNoon);

      final prompts = await getDailyPrompts(firestore);

      expect(prompts.single.promptId, awaitingPromptId);
    });

    // TODO(bug): the same midnight error shifts the query window by up to a
    // second either way, and isLessThan 23:59:59 skips the day's last second.
    // Not tested here: the result depends on the exact moment DateTime.now()
    // runs.
  });

  group('awaiting prompt helpers', () {
    // CreatePageContent.postData returns early for this prompt, so nothing is
    // posted until today's prompt exists.
    test('isAwaitingPrompt only matches the placeholder', () {
      expect(isAwaitingPrompt(awaitingPrompt()), isTrue);
      expect(isAwaitingPrompt(DbPrompt('a', 'b', 'day1', 'p1', '2026-11-01', 't')),
          isFalse);
    });
  });
}
