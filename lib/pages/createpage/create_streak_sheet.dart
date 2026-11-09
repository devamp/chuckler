import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/prompt_day.dart';
import '../../data/prompt_stats.dart';
import '../../state/friends_service.dart';
import '../../state/session_service.dart';
import 'create_stats.dart';

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];

/// Opens the streak calendar: which days the user answered, and where their
/// streak stands among friends
/// With [sample], the made-up history that goes with the sample prompts.
void showStreakSheet(BuildContext context, int streak, {bool sample = false}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black87,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => StreakSheet(streak: streak, sample: sample),
  );
}

class StreakSheet extends StatefulWidget {
  final int streak;

  final bool sample;

  const StreakSheet({super.key, required this.streak, this.sample = false});

  @override
  State<StreakSheet> createState() => _StreakSheetState();
}

class _StreakSheetState extends State<StreakSheet> {
  late final Future<StreakHistory> _history;
  /// today's prompt day, as a UTC midnight
  final DateTime _today = promptDayDate(promptDayId(DateTime.now().toUtc()));

  /// first day of the month on show
  late DateTime _month = DateTime.utc(_today.year, _today.month);

  @override
  void initState() {
    super.initState();
    final user =
        Provider.of<SessionService>(context, listen: false).loggedInUser;
    // friends were loaded by the Create tab
    final friends = {
      for (final f
          in Provider.of<FriendsService>(context, listen: false).friends)
        f.uid: f.username
    };
    _history = getStreakHistory(
        Provider.of<FirebaseFirestore>(context, listen: false),
        user?.uid ?? '',
        user?.username ?? '',
        sample: widget.sample,
        friends: friends);
  }

  bool get _onCurrentMonth =>
      _month.year == _today.year && _month.month == _today.month;

  void _changeMonth(int by) {
    setState(() {
      _month = DateTime.utc(_month.year, _month.month + by);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: FutureBuilder<StreakHistory>(
          future: _history,
          builder: (context, snapshot) {
            final history = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Colors.orangeAccent, size: 30),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('${widget.streak} DAY STREAK',
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'NewAmsterdam',
                                fontSize: 30)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (history == null)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                        child: CircularProgressIndicator(color: Colors.amber)),
                  )
                else ...[
                  monthHeader(history),
                  const SizedBox(height: 8),
                  calendar(history),
                  const SizedBox(height: 20),
                  if (history.standings.isNotEmpty) standings(history),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget monthHeader(StreakHistory history) {
    final daysInMonth = DateTime.utc(_month.year, _month.month + 1, 0).day;
    final answered = [
      for (int d = 1; d <= daysInMonth; d++)
        DateTime.utc(_month.year, _month.month, d)
    ].where(history.answeredOn).length;
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        Expanded(
          child: Column(
            children: [
              Text('${_monthNames[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              Text('$answered ${answered == 1 ? 'day' : 'days'} answered',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontFamily: 'OpenSans',
                      fontSize: 12)),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: _onCurrentMonth ? null : () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
          color: Colors.white,
          disabledColor: Colors.white24,
        ),
      ],
    );
  }

  /// Month grid, weeks starting on Sunday
  Widget calendar(StreakHistory history) {
    final daysInMonth = DateTime.utc(_month.year, _month.month + 1, 0).day;
    final blanks = _month.weekday % 7;
    final today = DateTime.utc(_today.year, _today.month, _today.day);
    return Column(
      children: [
        Row(
          children: [
            for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(
                child: Center(
                  child: Text(d,
                      style: const TextStyle(
                          color: Colors.white38,
                          fontFamily: 'OpenSans',
                          fontSize: 12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (int i = 0; i < blanks; i++) const SizedBox(),
            for (int d = 1; d <= daysInMonth; d++)
              dayCell(DateTime.utc(_month.year, _month.month, d), today,
                  history),
          ],
        ),
      ],
    );
  }

  /// A flame on answered days, a grey box with an X on missed ones, and
  /// the date for today (until answered) and days still to come
  Widget dayCell(DateTime day, DateTime today, StreakHistory history) {
    final answered = history.answeredOn(day);
    final missed = !answered && day.isBefore(today);
    final isToday = day == today;
    return Semantics(
      label: '${_monthNames[day.month - 1]} ${day.day}, '
          '${answered ? 'answered' : missed ? 'missed' : isToday ? 'today' : 'upcoming'}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: answered
              ? Colors.amberAccent.withValues(alpha: 0.15)
              : missed
                  ? Colors.grey.shade600
                  : Colors.transparent,
          border: isToday ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Center(
          child: answered
              ? const Icon(Icons.local_fire_department,
                  color: Colors.orangeAccent, size: 24)
              : missed
                  ? const Icon(Icons.close, color: Colors.black, size: 20)
                  : Text('${day.day}',
                      style: TextStyle(
                          color: isToday ? Colors.white : Colors.white24,
                          fontFamily: 'OpenSans',
                          fontSize: 13)),
        ),
      ),
    );
  }

  /// The top 5 current streaks among the user's friends, and the user's
  /// own place
  Widget standings(StreakHistory history) {
    final top = history.standings.where((f) => !f.isMe).take(5).toList();
    final place = history.myPlace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TOP FRIEND STREAKS',
            style: TextStyle(
                color: Colors.amberAccent,
                fontFamily: 'NewAmsterdam',
                fontSize: 22)),
        if (place > 0)
          Text("You're #$place of ${history.standings.length} with your friends",
              style: const TextStyle(
                  color: Colors.white70, fontFamily: 'OpenSans')),
        const SizedBox(height: 8),
        for (int i = 0; i < top.length; i++) standing(top[i], i),
      ],
    );
  }

  Widget standing(FriendStreak f, int i) {
    const medals = [Color(0xffffd230), Color(0xffc0c0c0), Color(0xffcd7f32)];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: i < 3 ? medals[i] : Colors.white24,
            child: Text('${i + 1}',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          FriendAvatar(username: f.username, index: i, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(f.username,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'OpenSans', fontSize: 16)),
          ),
          const Icon(Icons.local_fire_department,
              color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 2),
          Text('${f.streak}',
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'OpenSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
