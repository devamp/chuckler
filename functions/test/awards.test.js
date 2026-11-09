// Unit tests for awards.js and results.js; no emulator needed:
//   npx mocha test/awards.test.js

const assert = require("assert");
const {CATALOG, statValue, newAwards} = require("../awards");
const {finalStats, resultsText} = require("../results");

describe("awards catalog", () => {
  it("has unique ids and ascending tiers", () => {
    const ids = CATALOG.map((t) => t.id);
    assert.strictEqual(new Set(ids).size, ids.length);
    for (const track of CATALOG) {
      assert.ok(track.tiers.length > 0, track.id);
      if (track.comingSoon) continue;
      assert.ok(track.stat, track.id);
      const ats = track.tiers.map((t) => t.at);
      assert.deepStrictEqual([...ats].sort((a, b) => a - b), ats, track.id);
      for (const t of track.tiers) assert.ok(t.name && t.description);
    }
  });
});

describe("statValue", () => {
  it("reads plain stats and dotted paths", () => {
    const p = {stats: {answers: 3}, streak: {longest: 7}};
    assert.strictEqual(statValue(p, "answers"), 3);
    assert.strictEqual(statValue(p, "streak.longest"), 7);
    assert.strictEqual(statValue(p, "wins"), 0);
    assert.strictEqual(statValue({}, "streak.longest"), 0);
  });
});

describe("newAwards", () => {
  const catalog = [
    {id: "posts", stat: "answers", tiers: [
      {at: 1, name: "First Post"}, {at: 10, name: "10 Posts"}]},
    {id: "streak", stat: "streak.longest", tiers: [{at: 3, name: "S"}]},
    {id: "soon", comingSoon: true, tiers: [{name: "Soon"}]},
  ];

  it("awards a tier when the stat reaches it", () => {
    assert.deepStrictEqual(newAwards({stats: {answers: 1}}, catalog),
        [{id: "posts", at: 1, name: "First Post"}]);
  });

  it("doesn't award a tier twice", () => {
    const p = {stats: {answers: 5}, awards: {posts: {"1": "then"}}};
    assert.deepStrictEqual(newAwards(p, catalog), []);
  });

  it("awards every tier reached, including ones added later", () => {
    const p = {stats: {answers: 12}, streak: {longest: 3}};
    assert.deepStrictEqual(newAwards(p, catalog).map((a) => a.name),
        ["First Post", "10 Posts", "S"]);
  });

  it("skips coming-soon tracks and the default catalog works", () => {
    assert.deepStrictEqual(newAwards({}, catalog), []);
    assert.deepStrictEqual(newAwards({stats: {answers: 1}}).map((a) => a.id),
        ["posts"]);
  });
});

describe("results", () => {
  it("works out final stats and the win rate", () => {
    assert.deepStrictEqual(finalStats({counts: {wins: 3, dislikes: 1,
      votes: 6, matchups: 1, comments: 2}}),
    {wins: 3, dislikes: 1, votes: 6, matchups: 1, comments: 2,
      winRate: 0.75});
    assert.strictEqual(finalStats({}).winRate, null);
  });

  it("writes the notification text", () => {
    const a = (answer, wins, votes) =>
      ({post: {answer}, final: {wins, votes}});
    assert.strictEqual(resultsText("2026-11-08", [a("x", 0, 0)]),
        "Your answer from Nov 8 didn't get any votes.");
    assert.strictEqual(
        resultsText("2026-11-08", [a("dogs", 2, 4), a("cats", 5, 6)]),
        "Your 2 answers from Nov 8 won 7 of 10 votes. " +
        "Best: \"cats\" (5 wins)");
  });
});
