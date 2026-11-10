import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../data/friends.dart';
import '../../data/leaderboards.dart';
import '../../data/prompt_day.dart';
import '../../state/friends_service.dart';
import '../../state/leaderboard_service.dart';
import '../../state/moderation_service.dart';
import '../../state/session_service.dart';
import '../accountpage/account_posts.dart' show dayLabel;
import 'leaderboard_widgets.dart';

IconData _scopeIcon(LeaderScope s) => switch (s) {
      LeaderScope.friends => Icons.people_alt,
      LeaderScope.global => Icons.public,
    };

/// The Leaderboard tab: Friends or Global, and four boards (top answers,
/// wins, streak, posts), with This week / All time for wins and posts.
class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  FriendCard _me() {
    final user =
        Provider.of<SessionService>(context, listen: false).loggedInUser;
    return FriendCard(user?.uid ?? '', user?.username ?? '', '');
  }

  /// Loads the showing board if needed; friends first, for the friends
  /// boards
  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    final firestore = Provider.of<FirebaseFirestore>(context, listen: false);
    final service = Provider.of<LeaderboardService>(context, listen: false);
    final friends = Provider.of<FriendsService>(context, listen: false);
    final session = Provider.of<SessionService>(context, listen: false);
    final me = _me();
    if (service.scope == LeaderScope.friends &&
        (!friends.loaded || force) &&
        me.uid.isNotEmpty) {
      await friends.load(firestore, me.uid, session.email);
    }
    if (!mounted) return;
    await service.ensureLoaded(firestore, me, friends.friends, force: force);
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<LeaderboardService>(context);
    // a newly picked board loads once the frame is drawn
    if (service.current == null && !service.loading && !service.failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: primaryBackgroundGradient(context)),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _header(service),
              _boardChips(service),
              _subheader(service),
              Expanded(
                child: RefreshIndicator(
                  color: Colors.amber,
                  onRefresh: () => _load(force: true),
                  child: _content(service),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(LeaderboardService service) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text('Leaderboard',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'NewAmsterdam',
                    fontSize: 36)),
          ),
          _scopeButton(service),
        ],
      ),
    );
  }

  /// A pill like Home's filter, opening a menu of Friends and Global
  Widget _scopeButton(LeaderboardService service) {
    final current = service.scope;
    return PopupMenuButton<LeaderScope>(
      tooltip: 'Choose who to rank',
      initialValue: current,
      onSelected: service.setScope,
      offset: const Offset(0, 48),
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white12),
      ),
      itemBuilder: (context) => [
        for (final s in LeaderScope.values)
          PopupMenuItem<LeaderScope>(
            value: s,
            child: SizedBox(
              width: 200,
              child: Row(
                children: [
                  Icon(_scopeIcon(s),
                      color: s == current ? Colors.amberAccent : Colors.white,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.label,
                            style: TextStyle(
                                color: s == current
                                    ? Colors.amberAccent
                                    : Colors.white,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.bold)),
                        Text(s.description,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontFamily: 'OpenSans',
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_scopeIcon(current), color: Colors.amberAccent, size: 18),
            const SizedBox(width: 8),
            Text(current.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white70, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _boardChips(LeaderboardService service) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final b in LeaderBoard.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child:
                  _pill(b.label, b == service.board, () => service.setBoard(b)),
            ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? Colors.white : Colors.black54,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14)),
          ),
        ),
      ),
    );
  }

  /// The week toggle where it applies, and what the board stands for
  Widget _subheader(LeaderboardService service) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Row(
        children: [
          if (service.board.hasPeriod) ...[
            for (final p in LeaderPeriod.values)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _periodButton(
                    p, p == service.period, () => service.setPeriod(p)),
              ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(_caption(service),
                maxLines: 2,
                textAlign:
                    service.board.hasPeriod ? TextAlign.end : TextAlign.start,
                style: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'OpenSans',
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _periodButton(LeaderPeriod p, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? Colors.amberAccent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: selected ? Colors.amberAccent : Colors.white24),
        ),
        child: Text(p.label,
            style: TextStyle(
                color: selected ? Colors.amberAccent : Colors.white70,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  String _caption(LeaderboardService service) {
    final today = promptDayId(DateTime.now().toUtc());
    final board = service.current;
    final global = service.scope == LeaderScope.global;
    if (service.board == LeaderBoard.answers) {
      final day = board?.dayId ?? addDays(today, -1);
      final label = dayLabel(day, today);
      return 'Best answers from '
          '${label == 'Yesterday' || label == 'Today' ? label.toLowerCase() : label}';
    }
    if (service.board.hasPeriod && service.period == LeaderPeriod.week) {
      final start = board?.weekStart ?? weekStartId(today);
      final week = start == weekStartId(today)
          ? 'This week'
          : 'Week of ${dayLabel(start, today)}';
      return global ? '$week · updated daily' : '$week, since Monday';
    }
    return global ? 'Updated when each day ends' : 'Live';
  }

  Widget _content(LeaderboardService service) {
    final loaded = service.current;
    // people the user blocked, and answers with words they filter out, stay
    // off the boards
    final moderation = Provider.of<ModerationService>(context);
    final board = loaded == null
        ? null
        : Board(dayId: loaded.dayId, weekStart: loaded.weekStart, entries: [
            for (final e in loaded.entries)
              if (!moderation.isBlockedUsername(e.username)) e,
          ], answers: [
            for (final a in loaded.answers)
              if (!moderation.isBlockedUsername(a.username) &&
                  !moderation.filters('${a.before} ${a.answer} ${a.after}'))
                a,
          ]);
    if (board == null) {
      if (service.failed) {
        return _message(Icons.cloud_off, "Couldn't load the leaderboard",
            action: ('Try again', () => _load(force: true)));
      }
      return const Center(
          child: CircularProgressIndicator(color: Colors.amber));
    }
    final friendsScope = service.scope == LeaderScope.friends;
    final noFriends = friendsScope &&
        Provider.of<FriendsService>(context, listen: false).friendCount == 0;

    if (service.board == LeaderBoard.answers) {
      if (board.answers.isEmpty) {
        return _message(
            Icons.emoji_events_outlined,
            friendsScope
                ? (noFriends
                    ? 'Add friends to see how you stack up.'
                    : "No answers from you or your friends got votes "
                        "yesterday.")
                : 'Top answers appear once a day ends.');
      }
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: board.answers.length,
        itemBuilder: (context, i) =>
            TopAnswerCard(answer: board.answers[i], place: i + 1),
      );
    }

    if (noFriends) {
      return _message(
          Icons.people_alt_outlined, 'Add friends to see how you stack up.');
    }
    if (board.entries.isEmpty) {
      return _message(Icons.leaderboard_outlined,
          'Rankings appear after the first day ends.');
    }
    final places = ranks([for (final e in board.entries) e.value]);
    final top = board.entries.take(3).toList();
    final rest = board.entries.skip(3).toList();
    final pinMe = !friendsScope && board.me == null;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: rest.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Podium(
                    top: top,
                    places: places.take(3).toList(),
                    board: service.board);
              }
              return LeaderRow(
                  entry: rest[i - 1],
                  place: places[i + 2],
                  board: service.board);
            },
          ),
        ),
        if (pinMe)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: LeaderRow(
              entry: LeaderEntry(_me().username, '', 0, isMe: true),
              place: null,
              board: service.board,
              showValue: false,
              note: board.entries.length >= 50
                  ? 'Not in the top 50 yet'
                  : 'Not on this board yet',
            ),
          ),
      ],
    );
  }

  /// A centered message that still pulls to refresh
  Widget _message(IconData icon, String text,
      {(String, VoidCallback)? action}) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: box.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white38, size: 48),
                  const SizedBox(height: 12),
                  Text(text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                          fontSize: 17)),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    TextButton(
                        onPressed: action.$2,
                        child: Text(action.$1,
                            style: const TextStyle(
                                color: Colors.amberAccent,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.bold))),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
