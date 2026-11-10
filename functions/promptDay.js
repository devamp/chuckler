// Prompt days and answer streaks. The JS twin of lib/data/prompt_day.dart:
// keep the rollover rule in step with the app.

// A prompt day starts at 05:00 UTC for everyone.
const ROLLOVER_HOUR_UTC = 5;
const DAY_MS = 24 * 60 * 60 * 1000;
const DAY_ID = /^\d{4}-\d{2}-\d{2}$/;

/**
 * The prompt day (yyyy-MM-dd) that a moment falls in.
 * @param {Date} now
 * @return {string}
 */
function promptDayId(now) {
  const shifted = new Date(now.getTime() - ROLLOVER_HOUR_UTC * 60 * 60 * 1000);
  return shifted.toISOString().substring(0, 10);
}

/**
 * The day id `n` days after `dayId` (negative goes back).
 * @param {string} dayId
 * @param {number} n
 * @return {string}
 */
function addDays(dayId, n) {
  const t = Date.parse(`${dayId}T00:00:00Z`) + n * DAY_MS;
  return new Date(t).toISOString().substring(0, 10);
}

/**
 * When a prompt day opens.
 * @param {string} dayId
 * @return {Date}
 */
function promptDayStart(dayId) {
  return new Date(Date.parse(`${dayId}T00:00:00Z`) +
      ROLLOVER_HOUR_UTC * 60 * 60 * 1000);
}

/**
 * When a prompt day closes (the next one opens).
 * @param {string} dayId
 * @return {Date}
 */
function promptDayEnd(dayId) {
  return new Date(promptDayStart(dayId).getTime() + DAY_MS);
}

/**
 * Whole days from `a` to `b`.
 * @param {string} a
 * @param {string} b
 * @return {number}
 */
function daysBetween(a, b) {
  return Math.round(
      (Date.parse(`${b}T00:00:00Z`) - Date.parse(`${a}T00:00:00Z`)) / DAY_MS);
}

/**
 * Whether `s` is a valid yyyy-MM-dd day id.
 * @param {*} s
 * @return {boolean}
 */
function isDayId(s) {
  return typeof s === "string" && DAY_ID.test(s) &&
      !isNaN(Date.parse(`${s}T00:00:00Z`)) &&
      addDays(s, 0) === s;
}

/**
 * Marks `day` answered in a streak {days, from, current, longest}, where
 * days[i] is "1" or "0" for day from + i. Missed days are filled with "0".
 * Returns null when the day was already marked (nothing to write).
 * @param {object|undefined} streak the stored streak, or undefined
 * @param {string} day the answered prompt day (yyyy-MM-dd)
 * @return {object|null} the new streak, or null if unchanged
 */
function markStreakDay(streak, day) {
  let days = streak && typeof streak.days === "string" ? streak.days : "";
  let from = streak && isDayId(streak.from) ? streak.from : day;
  if (!days) from = day;

  const i = daysBetween(from, day);
  if (i < 0) {
    // An answer for a day before the string starts: extend it backwards.
    days = "1" + "0".repeat(-i - 1) + days;
    from = day;
  } else if (i < days.length) {
    if (days[i] === "1") return null;
    days = days.substring(0, i) + "1" + days.substring(i + 1);
  } else {
    days = days + "0".repeat(i - days.length) + "1";
  }
  return {days, from, ...streakRuns(days)};
}

/**
 * The trailing run of 1s (current) and the longest run of 1s.
 * @param {string} days
 * @return {{current: number, longest: number}}
 */
function streakRuns(days) {
  let longest = 0;
  let run = 0;
  for (const c of days) {
    run = c === "1" ? run + 1 : 0;
    if (run > longest) longest = run;
  }
  return {current: run, longest};
}

/**
 * The Monday that starts `dayId`'s week. Leaderboard weeks run Monday to
 * Sunday in prompt days, so they turn over at Monday's 05:00 UTC rollover.
 * @param {string} dayId
 * @return {string}
 */
function weekStart(dayId) {
  const dow = new Date(`${dayId}T00:00:00Z`).getUTCDay(); // 0 is Sunday
  return addDays(dayId, -((dow + 6) % 7));
}

module.exports = {
  ROLLOVER_HOUR_UTC,
  weekStart,
  promptDayId,
  promptDayStart,
  promptDayEnd,
  addDays,
  daysBetween,
  isDayId,
  markStreakDay,
  streakRuns,
};
