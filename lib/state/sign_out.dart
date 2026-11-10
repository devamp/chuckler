import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/isarDB.dart';
import 'account_service.dart';
import 'create_service.dart';
import 'feed_service.dart';
import 'friends_service.dart';
import 'leaderboard_service.dart';
import 'moderation_service.dart';
import 'prompt_service.dart';
import 'session_service.dart';
import 'voting_service.dart';

/// Captures the services and cache that hold a user's state, so they can
/// be cleared after the screens that read them are gone
class _UserState {
  final List<void Function()> _clears;
  final IsarService? _isar;

  _UserState(BuildContext context)
      : _clears = [
          Provider.of<PromptService>(context, listen: false).logout,
          Provider.of<CreateService>(context, listen: false).logout,
          Provider.of<VotingService>(context, listen: false).logout,
          Provider.of<FriendsService>(context, listen: false).logout,
          Provider.of<AccountService>(context, listen: false).logout,
          Provider.of<LeaderboardService>(context, listen: false).logout,
          Provider.of<FeedService>(context, listen: false).logout,
          Provider.of<ModerationService>(context, listen: false).logout,
          // last: many screens read the signed-in user with `!`
          Provider.of<SessionService>(context, listen: false).logout,
        ],
        _isar = _maybeIsar(context);

  static IsarService? _maybeIsar(BuildContext context) {
    try {
      return Provider.of<IsarService>(context, listen: false);
    } catch (e) {
      return null; // not provided (tests)
    }
  }

  Future<void> clear() async {
    for (final c in _clears) {
      c();
    }
    try {
      await _isar?.clearAll();
    } catch (e) {
      debugPrint('clear cache: $e');
    }
  }
}

/// How long the old screens take to leave after the login screen is pushed
/// (a page transition, plus a little)
const Duration _leaveTime = Duration(milliseconds: 450);

/// Returns to the login screen with nothing to go back to, then clears
/// every service and the on-device cache so nothing of this user is left
/// for the next one. Signs out of Firebase unless [alreadySignedOut] (a
/// deleted account is signed out already). Used by Log out and Delete
/// account.
Future<void> signOut(BuildContext context,
    {FirebaseAuth? auth, bool alreadySignedOut = false}) async {
  final state = _UserState(context);
  final navigator = Navigator.of(context, rootNavigator: true);
  if (!alreadySignedOut) {
    try {
      await (auth ?? FirebaseAuth.instance).signOut();
    } catch (e) {
      debugPrint('sign out: $e');
    }
  }
  navigator.pushNamedAndRemoveUntil('/', (_) => false);
  // The screens being removed still read the user (often with `!`) until
  // the login screen has slid over them; clear only once they're gone.
  await Future<void>.delayed(_leaveTime);
  await state.clear();
}
