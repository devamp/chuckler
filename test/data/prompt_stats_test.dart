// Tests for the Create tab's stats helpers and sample data.

import 'package:chuckler/data/matchups.dart';
import 'package:chuckler/data/prompt_stats.dart';
import 'package:chuckler/data/sample_prompts.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/createpage/create_prompt_card.dart';
import 'package:flutter_test/flutter_test.dart';

DbPrompt typed(String? type) => DbPrompt('', '', 'd', 'p', null, type);

void main() {
  test('segmentOf reads the prompt type, defaulting to global', () {
    expect(segmentOf(typed('friends')), Segment.friends);
    expect(segmentOf(typed('Local')), Segment.local);
    expect(segmentOf(typed('global')), Segment.global);
    expect(segmentOf(typed('daily')), Segment.global);
    expect(segmentOf(typed(null)), Segment.global);
  });

  test('compactCount shortens large numbers', () {
    expect(compactCount(999), '999');
    expect(compactCount(1000), '1k');
    expect(compactCount(1250), '1.3k');
    expect(compactCount(10000), '10k');
    expect(compactCount(152000), '152k');
    expect(compactCount(2000000), '2M');
  });

  test('winRate and topPercent', () {
    const s = AnswerStats(votes: 36, wins: 23, rank: 12);
    expect(s.winRate, 64);
    expect(s.topPercent(340), 4);
    expect(const AnswerStats().winRate, 0);
    expect(const AnswerStats().topPercent(340), 0);
    expect(const AnswerStats(rank: 1).topPercent(100000), 1);
  });

  test('timeLeftLabel counts down to the next UTC midnight', () {
    expect(timeLeftLabel(DateTime.utc(2026, 11, 2, 18, 48)), '5h 12m left');
    expect(timeLeftLabel(DateTime.utc(2026, 11, 2, 23, 30)), '30m left');
    expect(timeLeftLabel(DateTime.utc(2026, 11, 2, 23, 59, 50)), '1m left');
  });

  test('sample stats depend on whether and when you answered', () {
    final prompts = samplePrompts();
    final iceCream = prompts.firstWhere((p) => p.promptId == 'sample-ice-cream');
    final seeded = sampleAnsweredPosts('me', 'caden')['sample-ice-cream'];

    expect(samplePromptStats(iceCream, null).mine, isNull);
    expect(samplePromptStats(iceCream, seeded).mine!.rank, 12);

    final fresh = DbPost('sample-x', 'new', 'caden', 'me', 0, 0, 0,
        'sample-ice-cream', samplePromptDayId);
    expect(samplePromptStats(iceCream, fresh).mine!.matchups, 0);
    expect(samplePromptStats(iceCream, null).answers, 340);
  });
}
