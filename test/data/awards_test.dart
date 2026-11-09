import 'dart:io';

import 'package:chuckler/data/awards.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // the same file the Cloud Functions award from
  final catalog =
      parseAwardCatalog(File('functions/awards.json').readAsStringSync());

  group('catalog', () {
    test('parses the shared catalog', () {
      expect(catalog.map((t) => t.id),
          containsAll(['posts', 'streak', 'friends', 'comments', 'wins']));
      expect(catalog.map((t) => t.id).toSet().length, catalog.length);
      final posts = catalog.firstWhere((t) => t.id == 'posts');
      expect(posts.stat, 'answers');
      expect(posts.tiers.map((t) => t.at), [1, 100]);
      expect(posts.tiers.first.name, 'First Post');
    });

    test('coming-soon tracks have no stat or thresholds', () {
      final soon = catalog.where((t) => t.comingSoon).toList();
      expect(soon.map((t) => t.id), ['leaderboard', 'top1', 'referral']);
      for (final t in soon) {
        expect(t.stat, isNull);
        expect(t.tiers.every((tier) => tier.at == null), isTrue);
      }
    });
  });

  group('profileStat', () {
    final profile = {
      'stats': {'answers': 3, 'wins': 2.0},
      'streak': {'longest': 7},
    };
    test('reads stats and dotted paths, 0 when missing', () {
      expect(profileStat(profile, 'answers'), 3);
      expect(profileStat(profile, 'wins'), 2);
      expect(profileStat(profile, 'streak.longest'), 7);
      expect(profileStat(profile, 'comments'), 0);
      expect(profileStat({}, 'streak.longest'), 0);
    });
  });

  group('awardProgress', () {
    test('a new user has earned nothing', () {
      final progress = awardProgress(catalog, {});
      expect(progress.length, catalog.length);
      final posts = progress.first;
      expect(posts.latest, isNull);
      expect(posts.next!.name, 'First Post');
      expect(posts.fraction, 0);
    });

    test('earned tiers, the next tier and progress toward it', () {
      final when = DateTime.utc(2026, 11, 8);
      final progress = awardProgress(catalog, {
        'stats': {'answers': 37},
        'awards': {
          'posts': {'1': Timestamp.fromDate(when)},
        },
      });
      final posts = progress.firstWhere((p) => p.track.id == 'posts');
      expect(posts.value, 37);
      expect(posts.latest!.name, 'First Post');
      expect(posts.earned[1]!.isAtSameMomentAs(when), isTrue);
      expect(posts.next!.name, '100 Posts');
      expect(posts.fraction, closeTo(0.37, 0.001));
      expect(posts.shown.name, '100 Posts');
    });

    test('every tier earned is complete', () {
      final progress = awardProgress(catalog, {
        'stats': {'answers': 150},
        'awards': {
          'posts': {'1': null, '100': null},
        },
      });
      final posts = progress.firstWhere((p) => p.track.id == 'posts');
      expect(posts.next, isNull);
      expect(posts.fraction, 1);
      expect(posts.latest!.name, '100 Posts');
      expect(posts.earned[100], isNull); // earned, date unknown
    });

    test('the stat alone does not earn a tier; the server awards it', () {
      final progress = awardProgress(catalog, {
        'stats': {'answers': 5}
      });
      final posts = progress.firstWhere((p) => p.track.id == 'posts');
      expect(posts.latest, isNull);
      expect(posts.fraction, 1); // ready, waiting for the server
    });

    test('unknown awards on the profile are ignored', () {
      final progress = awardProgress(catalog, {
        'awards': {
          'gone': {'5': null},
          'posts': 'junk',
        },
      });
      expect(progress.every((p) => p.earned.isEmpty), isTrue);
    });
  });
}
