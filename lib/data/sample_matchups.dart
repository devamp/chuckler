import 'matchups.dart';

// Example matchups for building the voting screen before it reads Firestore.
// Fresh objects on every call, so local vote counts never leak between uses.

List<Matchup> sampleMatchups() {
  const day = 'sample-day';
  return [
    Matchup(
      id: 'sample-1',
      promptId: 'pilot',
      promptDateId: day,
      promptBefore: 'The last thing you want to hear your pilot say is "',
      promptAfter: '"',
      segment: Segment.global,
      top: MatchupAnswer(
          postId: 's1a',
          uid: 'sample-u1',
          username: 'skyler',
          answer: 'Anyone know which button is autopilot?',
          wins: 31,
          downvotes: 2),
      bottom: MatchupAnswer(
          postId: 's1b',
          uid: 'sample-u2',
          username: 'marco',
          answer: 'Okay, this is my first time without the simulator',
          wins: 19,
          downvotes: 4),
    ),
    Matchup(
      id: 'sample-2',
      promptId: 'pilot',
      promptDateId: day,
      promptBefore: 'The last thing you want to hear your pilot say is "',
      promptAfter: '"',
      segment: Segment.friends,
      top: MatchupAnswer(
          postId: 's2a',
          uid: 'sample-u3',
          username: 'jen',
          answer: 'Hold my coffee',
          wins: 8,
          downvotes: 0),
      bottom: MatchupAnswer(
          postId: 's2b',
          uid: 'sample-u4',
          username: 'devon',
          answer: 'We will be landing shortly. Somewhere.',
          wins: 12,
          downvotes: 1),
    ),
    Matchup(
      id: 'sample-3',
      promptId: 'roommate',
      promptDateId: day,
      promptBefore: 'My roommate\'s most annoying habit is ',
      promptAfter: '.',
      segment: Segment.local,
      top: MatchupAnswer(
          postId: 's3a',
          uid: 'sample-u5',
          username: 'priya',
          answer: 'narrating their own life in the third person',
          wins: 0,
          downvotes: 0),
      bottom: MatchupAnswer(
          postId: 's3b',
          uid: 'sample-u6',
          username: 'tomas',
          answer: 'labeling the ice cubes',
          wins: 0,
          downvotes: 0),
    ),
    Matchup(
      id: 'sample-4',
      promptId: 'roommate',
      promptDateId: day,
      promptBefore: 'My roommate\'s most annoying habit is ',
      promptAfter: '.',
      segment: Segment.global,
      top: MatchupAnswer(
          postId: 's4a',
          uid: 'sample-u7',
          username: 'ava',
          answer: 'practicing the bagpipes at 6 a.m.',
          wins: 44,
          downvotes: 3),
      bottom: MatchupAnswer(
          postId: 's4b',
          uid: 'sample-u8',
          username: 'kai',
          answer: 'reviewing my cooking on Yelp',
          wins: 51,
          downvotes: 2),
    ),
    Matchup(
      id: 'sample-5',
      promptId: 'superpower',
      promptDateId: day,
      promptBefore: 'The most useless superpower would be ',
      promptAfter: '.',
      segment: Segment.global,
      top: MatchupAnswer(
          postId: 's5a',
          uid: 'sample-u9',
          username: 'lena',
          answer: 'knowing exactly how many grapes are in a bag',
          wins: 27,
          downvotes: 1),
      bottom: MatchupAnswer(
          postId: 's5b',
          uid: 'sample-u10',
          username: 'omar',
          answer: 'turning invisible, but only when nobody is looking',
          wins: 36,
          downvotes: 0),
    ),
  ];
}
