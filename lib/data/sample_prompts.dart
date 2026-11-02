import '../database/models.dart';
import 'prompt_stats.dart';

// Example prompts and stats for building the Create tab before the stats
// exist in Firestore. Sample prompts are only added in debug builds when no
// real prompt is live, and answers to them stay on the phone.

/// promptDateId shared by every sample prompt
const String samplePromptDayId = 'sample-day';

/// Sample answer streak, in days
const int sampleStreak = 4;

bool isSamplePrompt(DbPrompt prompt) =>
    prompt.promptDateId == samplePromptDayId;

/// postId prefix of the sample answers that come with rich stats
const String _seededPostPrefix = 'sample-seeded-';

/// Fresh objects on every call, so local state never leaks between uses
List<DbPrompt> samplePrompts() {
  DbPrompt prompt(String id, String before, String after, String type,
      int responses) {
    return DbPrompt(before, after, samplePromptDayId, id, null, type)
      ..responses = responses;
  }

  return [
    prompt('sample-date', 'The worst thing to say on a first date is "', '"',
        'friends', 9),
    prompt('sample-ice-cream', 'A rejected ice cream flavor: ', '', 'global',
        340),
    prompt('sample-bus', 'The real reason the bus is late today: ', '',
        'local', 57),
  ];
}

/// The user's answers to sample prompts that start out answered, keyed by
/// promptId
Map<String, DbPost> sampleAnsweredPosts(String uid, String username) {
  return {
    'sample-ice-cream': DbPost('${_seededPostPrefix}ice-cream',
        'Rocky Road Rage', username, uid, 0, 0, 23, 'sample-ice-cream',
        samplePromptDayId)
      ..mine = true,
  };
}

/// Made-up stats that stay the same for the same prompt
PromptStats samplePromptStats(DbPrompt prompt, DbPost? myPost) {
  final seed = (prompt.promptId ?? '').codeUnits.fold(0, (a, b) => a + b);
  final answers = prompt.responses > 0 ? prompt.responses : 40 + seed % 300;
  final friends = switch (prompt.promptId) {
    'sample-date' => _sampleFriends,
    'sample-ice-cream' => _sampleFriends.take(2).toList(),
    'sample-bus' => <String>[],
    _ => _sampleFriends.take(seed % 4).toList(),
  };

  AnswerStats? mine;
  if (myPost != null) {
    if ((myPost.postId ?? '').startsWith(_seededPostPrefix) ||
        !isSamplePrompt(prompt)) {
      // an answer that has been out for a while
      mine = AnswerStats(
        matchups: 41,
        votes: 36,
        wins: 23,
        downvotes: 3,
        rank: (answers * 0.035).ceil(),
        winsByHour: const [2, 5, 3, 7, 4, 2],
      );
    } else {
      // just posted, not in a matchup yet
      mine = const AnswerStats();
    }
  }

  return PromptStats(
    answers: answers,
    likes: answers ~/ 3 + seed % 20,
    friendsAnswered: friends,
    mine: mine,
  );
}

const List<String> _sampleFriends = [
  'skyler',
  'marco',
  'ava',
  'jules',
  'priya',
  'theo',
];

/// A sampleStreak-day streak ending today, gaps before it, and friends
/// around the user in the standings
StreakHistory sampleStreakHistory(DateTime nowUtc, String username) {
  final today = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
  const daysAgo = [0, 1, 2, 3, 6, 7, 9, 12, 13, 14, 15, 18, 20, 21, 27, 33, 34];
  return StreakHistory(
    answeredDays: {
      for (final d in daysAgo) today.subtract(Duration(days: d)),
    },
    standings: [
      const FriendStreak('ava', 12),
      const FriendStreak('theo', 9),
      const FriendStreak('marco', 7),
      FriendStreak(username.isEmpty ? 'you' : username, sampleStreak,
          isMe: true),
      const FriendStreak('skyler', 3),
      const FriendStreak('jules', 1),
      const FriendStreak('priya', 0),
    ],
  );
}
