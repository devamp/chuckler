// Prompt days roll over at one fixed time for everyone, so friends share the
// same "today". functions/ uses the same rule; keep the two in step.

/// A prompt day starts at 05:00 UTC: midnight Eastern standard time (1am in
/// summer), 10pm Mountain (11pm in summer).
const int rolloverHourUtc = 5;

/// The prompt day (yyyy-MM-dd) that nowUtc falls in. Also the PromptDays
/// doc id and every prompt's promptDateId.
String promptDayId(DateTime nowUtc) {
  final shifted = nowUtc.toUtc().subtract(const Duration(hours: rolloverHourUtc));
  return shifted.toIso8601String().substring(0, 10);
}

/// When a prompt day opens
DateTime promptDayStart(String dayId) =>
    DateTime.parse('${dayId}T00:00:00Z')
        .add(const Duration(hours: rolloverHourUtc));

/// When a prompt day closes (the next one opens)
DateTime promptDayEnd(String dayId) =>
    promptDayStart(dayId).add(const Duration(days: 1));

/// The calendar day a prompt day stands for, as a UTC midnight
DateTime promptDayDate(String dayId) => DateTime.parse('${dayId}T00:00:00Z');

/// History docs hold one month of answers each: yyyy-MM
String historyMonthId(String dayId) => dayId.substring(0, 7);
