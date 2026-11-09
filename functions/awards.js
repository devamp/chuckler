// Awards. The catalog (awards.json) is shared with the app, which loads the
// same file as an asset for names, descriptions and progress. Each award is
// a track: a stat on FriendView/profile and a list of tiers, each earned
// when the stat reaches `at`. Earned tiers are stored on the profile as
// awards.{trackId}.{at} = when. Adding a tier is one line in awards.json;
// a new kind of award needs a track plus whatever keeps its stat.

const CATALOG = require("./awards.json");

/**
 * Reads a dotted stat path ("answers", "streak.longest") from a profile.
 * Plain names are under `stats`; dotted ones start at the profile root.
 * @param {object} profile
 * @param {string} stat
 * @return {number}
 */
function statValue(profile, stat) {
  if (!profile || !stat) return 0;
  let v = stat.includes(".") ? profile : (profile.stats || {});
  for (const part of stat.split(".")) {
    v = v == null ? undefined : v[part];
  }
  return typeof v === "number" ? v : 0;
}

/**
 * The tiers `after` qualifies for that aren't stored as earned yet.
 * Comparing against what's stored (not the old stat) means a tier added to
 * the catalog later is awarded the next time any stat changes.
 * @param {object} after the profile with its new stats
 * @param {Array<object>} catalog
 * @return {Array<{id: string, at: number, name: string}>}
 */
function newAwards(after, catalog = CATALOG) {
  const earned = (after && after.awards) || {};
  const out = [];
  for (const track of catalog) {
    if (track.comingSoon || !track.stat) continue;
    const value = statValue(after, track.stat);
    const have = earned[track.id] || {};
    for (const tier of track.tiers) {
      if (typeof tier.at !== "number") continue;
      if (value >= tier.at && have[String(tier.at)] == null) {
        out.push({id: track.id, at: tier.at, name: tier.name});
      }
    }
  }
  return out;
}

module.exports = {CATALOG, statValue, newAwards};
