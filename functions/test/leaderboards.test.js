// Unit tests for the weekly stats and the leaderboard ranking helpers (no
// emulator needed).

const assert = require("assert");
const {weekStart} = require("../promptDay");
const {nextWeek, applyStats} = require("../profile");
const {topAnswers, liveStreak, boardEntries} = require("../leaderboards");

describe("weekStart", () => {
  it("is the Monday of the prompt day's week", () => {
    assert.strictEqual(weekStart("2026-11-09"), "2026-11-09"); // Monday
    assert.strictEqual(weekStart("2026-11-15"), "2026-11-09"); // Sunday
    assert.strictEqual(weekStart("2026-11-08"), "2026-11-02"); // Sunday
    assert.strictEqual(weekStart("2027-01-01"), "2026-12-28"); // over a year
  });
});

describe("weekly stats", () => {
  it("adds to the current week", () => {
    assert.deepStrictEqual(
        nextWeek({start: "2026-11-09", answers: 2, wins: 5}, "2026-11-11",
            {answers: 1}),
        {start: "2026-11-09", answers: 3, wins: 5});
  });

  it("starts a new week from zero, clearing every count", () => {
    assert.deepStrictEqual(
        nextWeek({start: "2026-11-02", answers: 9, wins: 7}, "2026-11-09",
            {wins: 1}),
        {start: "2026-11-09", answers: 0, wins: 1});
    assert.deepStrictEqual(nextWeek(undefined, "2026-11-09", {answers: 1}),
        {start: "2026-11-09", answers: 1, wins: 0});
  });

  it("leaves the week alone for older days, other stats or no day", () => {
    const week = {start: "2026-11-09", answers: 1, wins: 1};
    assert.strictEqual(nextWeek(week, "2026-11-08", {wins: 1}), null);
    assert.strictEqual(nextWeek(week, "2026-11-10", {comments: 1}), null);
    assert.strictEqual(nextWeek(week, null, {wins: 1}), null);
  });
});

describe("applyStats weeks", () => {
  /**
   * Runs applyStats against a fake transaction.
   * @param {object} profile
   * @param {object} change
   * @return {object} the profile update written
   */
  function apply(profile, change) {
    const writes = [];
    const tx = {set: (ref, data) => writes.push(data)};
    const db = {collection: () => ({doc: () => ({collection: () => ({
      doc: () => ({})})})})};
    applyStats(tx, db, "u1", profile, change);
    return writes[0];
  }

  it("keeps last week when a new one starts", () => {
    const update = apply({week: {start: "2026-11-02", answers: 5, wins: 2}},
        {deltas: {answers: 1}, day: "2026-11-09"});
    assert.deepStrictEqual(update.week,
        {start: "2026-11-09", answers: 1, wins: 0});
    assert.deepStrictEqual(update.weekPrev,
        {start: "2026-11-02", answers: 5, wins: 2});
  });

  it("doesn't touch weekPrev within a week", () => {
    const update = apply({week: {start: "2026-11-09", answers: 1, wins: 0}},
        {deltas: {wins: 1}, day: "2026-11-10"});
    assert.strictEqual(update.weekPrev, undefined);
    assert.strictEqual(update.week.wins, 1);
  });
});

describe("leaderboards", () => {
  const post = (id, uid, wins, votes, extra = {}) =>
    ({id, data: {uid, answer: id, counts: {wins, votes}, ...extra}});

  it("ranks answers by wins, then win rate, then votes", () => {
    const ranked = topAnswers([
      post("a", "u1", 2, 10),
      post("b", "u2", 3, 9),
      post("c", "u3", 2, 4),
      post("d", "u4", 0, 4),
      post("e", "u5", 0, 6),
    ]);
    assert.deepStrictEqual(ranked.map((p) => p.id),
        ["b", "c", "a", "e", "d"]);
  });

  it("leaves out friend prompt answers and unvoted ones", () => {
    const ranked = topAnswers([
      post("friend", "u1", 9, 9, {promptSource: "friends"}),
      post("unvoted", "u2", 0, 0),
      post("daily", "u3", 1, 2),
    ]);
    assert.deepStrictEqual(ranked.map((p) => p.id), ["daily"]);
  });

  it("counts a streak only while it's alive at the end of the day", () => {
    const streak = {days: "0111", from: "2026-11-05", current: 3};
    // last answered day is 2026-11-08
    assert.strictEqual(liveStreak(streak, "2026-11-08"), 3);
    assert.strictEqual(liveStreak(streak, "2026-11-07"), 3);
    assert.strictEqual(liveStreak(streak, "2026-11-09"), 0);
    assert.strictEqual(liveStreak(undefined, "2026-11-09"), 0);
  });

  it("drops zeros and unknown or official users from boards", () => {
    const users = new Map([["u1", {username: "ava", photoUrl: ""}],
      ["u2", {username: "ben", photoUrl: "p"}]]);
    assert.deepStrictEqual(boardEntries([
      {uid: "u2", value: 5}, {uid: "chuckler", value: 4},
      {uid: "u1", value: 3}, {uid: "u3", value: 0},
    ], users), [
      {username: "ben", photoUrl: "p", value: 5},
      {username: "ava", photoUrl: "", value: 3},
    ]);
  });
});
