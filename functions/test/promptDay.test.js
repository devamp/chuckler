// Unit tests for the prompt-day and streak helpers (no emulator needed).

const assert = require("assert");
const {
  promptDayId, addDays, isDayId, markStreakDay, streakRuns,
} = require("../promptDay");

describe("promptDayId", () => {
  it("rolls over at 05:00 UTC", () => {
    assert.strictEqual(promptDayId(new Date("2026-11-08T04:59:59Z")),
        "2026-11-07");
    assert.strictEqual(promptDayId(new Date("2026-11-08T05:00:00Z")),
        "2026-11-08");
    assert.strictEqual(promptDayId(new Date("2027-01-01T03:00:00Z")),
        "2026-12-31");
  });

  it("adds days across months", () => {
    assert.strictEqual(addDays("2026-11-30", 1), "2026-12-01");
    assert.strictEqual(addDays("2026-03-01", -1), "2026-02-28");
  });

  it("validates day ids", () => {
    assert.ok(isDayId("2026-11-08"));
    assert.ok(!isDayId("2026-02-30"));
    assert.ok(!isDayId("20261108"));
    assert.ok(!isDayId(undefined));
  });
});

describe("markStreakDay", () => {
  it("starts a streak when there is none", () => {
    assert.deepStrictEqual(markStreakDay(undefined, "2026-11-08"),
        {days: "1", from: "2026-11-08", current: 1, longest: 1});
  });

  it("appends the next day", () => {
    const s = {days: "11", from: "2026-11-06", current: 2, longest: 2};
    assert.deepStrictEqual(markStreakDay(s, "2026-11-08"),
        {days: "111", from: "2026-11-06", current: 3, longest: 3});
  });

  it("fills missed days with 0", () => {
    const s = {days: "111", from: "2026-11-01", current: 3, longest: 3};
    assert.deepStrictEqual(markStreakDay(s, "2026-11-06"),
        {days: "111001", from: "2026-11-01", current: 1, longest: 3});
  });

  it("returns null when the day is already marked", () => {
    const s = {days: "101", from: "2026-11-06", current: 1, longest: 1};
    assert.strictEqual(markStreakDay(s, "2026-11-08"), null);
  });

  it("fills a missed day answered late", () => {
    const s = {days: "101", from: "2026-11-06", current: 1, longest: 1};
    assert.deepStrictEqual(markStreakDay(s, "2026-11-07"),
        {days: "111", from: "2026-11-06", current: 3, longest: 3});
  });

  it("extends backwards for a day before the string starts", () => {
    const s = {days: "1", from: "2026-11-08", current: 1, longest: 1};
    assert.deepStrictEqual(markStreakDay(s, "2026-11-06"),
        {days: "101", from: "2026-11-06", current: 1, longest: 1});
  });

  it("counts runs", () => {
    assert.deepStrictEqual(streakRuns("1101110001111"),
        {current: 4, longest: 4});
    assert.deepStrictEqual(streakRuns("11111001"), {current: 1, longest: 5});
    assert.deepStrictEqual(streakRuns(""), {current: 0, longest: 0});
  });
});
