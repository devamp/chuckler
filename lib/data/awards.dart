import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/services.dart';

// Awards. The catalog is functions/awards.json, shared with the Cloud
// Functions that award them, and bundled with the app as an asset so names,
// descriptions and tiers can't drift between the two. Each award is a track:
// a stat on FriendView/profile and tiers earned when the stat reaches `at`.
// Earned tiers are on the profile as awards.{trackId}.{at} = when.
// To add a tier, add a line to awards.json; see functions/awards.js.

const String awardCatalogAsset = 'functions/awards.json';

class AwardTier {
  /// the stat value that earns it; null for coming-soon awards
  final int? at;
  final String name;
  final String description;

  const AwardTier(this.at, this.name, this.description);

  factory AwardTier.fromJson(Map<String, dynamic> j) => AwardTier(
      (j['at'] as num?)?.toInt(),
      j['name'] as String? ?? '',
      j['description'] as String? ?? '');
}

class AwardTrack {
  final String id;

  /// the profile stat it counts, e.g. "answers" (under stats) or
  /// "streak.longest" (a path from the profile root)
  final String? stat;
  final bool comingSoon;
  final List<AwardTier> tiers;

  const AwardTrack(this.id, this.stat, this.comingSoon, this.tiers);

  factory AwardTrack.fromJson(Map<String, dynamic> j) => AwardTrack(
          j['id'] as String, j['stat'] as String?, j['comingSoon'] == true, [
        for (final t in (j['tiers'] as List? ?? const []))
          AwardTier.fromJson(Map<String, dynamic>.from(t as Map)),
      ]);
}

List<AwardTrack> parseAwardCatalog(String json) => [
      for (final t in jsonDecode(json) as List)
        AwardTrack.fromJson(Map<String, dynamic>.from(t as Map)),
    ];

Future<List<AwardTrack>> loadAwardCatalog([AssetBundle? bundle]) async =>
    parseAwardCatalog(
        await (bundle ?? rootBundle).loadString(awardCatalogAsset));

/// A stat from a FriendView/profile map: plain names are under `stats`,
/// dotted paths start at the profile root. The twin of statValue in
/// functions/awards.js.
int profileStat(Map<String, dynamic> profile, String stat) {
  dynamic v = stat.contains('.') ? profile : profile['stats'];
  for (final part in stat.split('.')) {
    v = v is Map ? v[part] : null;
  }
  return v is num ? v.toInt() : 0;
}

/// When each tier of each track was earned, from the profile's `awards`
/// (trackId -> {"at" -> timestamp})
Map<String, Map<int, DateTime?>> parseEarnedAwards(dynamic awards) {
  final out = <String, Map<int, DateTime?>>{};
  if (awards is! Map) return out;
  awards.forEach((id, tiers) {
    if (tiers is! Map) return;
    out[id as String] = {
      for (final e in tiers.entries)
        if (int.tryParse('${e.key}') != null)
          int.parse('${e.key}'):
              e.value is Timestamp ? (e.value as Timestamp).toDate() : null,
    };
  });
  return out;
}

/// How far the user is along one track
class AwardProgress {
  final AwardTrack track;

  /// the stat's current value
  final int value;

  /// earned tiers' `at` -> when (null if the date is unknown)
  final Map<int, DateTime?> earned;

  const AwardProgress(this.track, this.value, this.earned);

  bool get comingSoon => track.comingSoon;

  bool isEarned(AwardTier tier) =>
      tier.at != null && earned.containsKey(tier.at);

  List<AwardTier> get earnedTiers => track.tiers.where(isEarned).toList();

  /// the highest tier earned, if any
  AwardTier? get latest => earnedTiers.isEmpty ? null : earnedTiers.last;

  /// the first tier not earned yet; null when all are earned
  AwardTier? get next {
    for (final t in track.tiers) {
      if (!isEarned(t)) return t;
    }
    return null;
  }

  /// the tier the badge shows: the next one to earn, or the top one
  AwardTier get shown => next ?? track.tiers.last;

  /// 0..1 toward the next tier (1 when everything is earned)
  double get fraction {
    final n = next;
    if (n == null) return 1;
    if (n.at == null || n.at == 0) return 0;
    return (value / n.at!).clamp(0, 1).toDouble();
  }
}

/// Progress on every track in the catalog, in catalog order
List<AwardProgress> awardProgress(
    List<AwardTrack> catalog, Map<String, dynamic> profile) {
  final earned = parseEarnedAwards(profile['awards']);
  return [
    for (final track in catalog)
      AwardProgress(
          track,
          track.stat == null ? 0 : profileStat(profile, track.stat!),
          earned[track.id] ?? const {}),
  ];
}
