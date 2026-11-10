import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../state/session_service.dart';
import '../../state/sign_out.dart';
import '../constant_strings.dart';
import '../createpage/create_stats.dart';
import 'settings-routes/delete_account_page.dart';
import 'settings-routes/hidden_prompts_page.dart';

const _groupColor = Color(0xFF1C1C1E);

/// Settings, from the Account tab: your account, hidden prompts, about and
/// support, and logging out or deleting the account.
class Settings extends StatelessWidget {
  /// for tests; the real FirebaseAuth otherwise
  final FirebaseAuth? auth;

  /// the app's version line; read from the bundle when null
  final Future<String> Function()? versionLoader;

  const Settings({super.key, this.auth, this.versionLoader});

  FirebaseAuth get _auth => auth ?? FirebaseAuth.instance;

  static Future<String> _bundleVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionService>(context);
    final username = session.loggedInUser?.username ?? '';
    final email = session.email ?? _auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _profileHeader(username, email),
          _sectionTitle('Account'),
          _group([
            _row(Icons.person_outline, 'Username',
                value: username, hint: "Usernames can't be changed yet"),
            _row(Icons.mail_outline, 'Email', value: email),
            _row(Icons.key_outlined, 'Change password',
                chevron: true,
                onTap: email.isEmpty
                    ? null
                    : () => _changePassword(context, email)),
          ]),
          _sectionTitle('Home'),
          _group([
            _row(Icons.visibility_off_outlined, 'Hidden prompts',
                chevron: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const HiddenPromptsPage()))),
          ]),
          _sectionTitle('About'),
          _group([
            if (supportEmail.isNotEmpty)
              _row(Icons.chat_bubble_outline, 'Contact us',
                  chevron: true,
                  onTap: () => _open(
                      context,
                      Uri(
                          scheme: 'mailto',
                          path: supportEmail,
                          query: 'subject=Chuckler feedback'))),
            if (termsUrl.isNotEmpty)
              _row(Icons.description_outlined, 'Terms of Service',
                  chevron: true,
                  onTap: () => _open(context, Uri.parse(termsUrl))),
            if (privacyUrl.isNotEmpty)
              _row(Icons.privacy_tip_outlined, 'Privacy Policy',
                  chevron: true,
                  onTap: () => _open(context, Uri.parse(privacyUrl))),
            FutureBuilder<String>(
              future: (versionLoader ?? _bundleVersion)(),
              builder: (context, snap) =>
                  _row(Icons.info_outline, 'Version', value: snap.data ?? ''),
            ),
          ]),
          const SizedBox(height: 28),
          _group([
            _row(Icons.logout, 'Log out', onTap: () => _confirmLogout(context)),
          ]),
          const SizedBox(height: 12),
          _group([
            _row(Icons.delete_outline, 'Delete account',
                danger: true,
                chevron: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DeleteAccountPage(auth: auth)))),
          ]),
        ],
      ),
    );
  }

  Widget _profileHeader(String username, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          FriendAvatar(
              username: username.isEmpty ? '?' : username,
              index: username.codeUnits.fold(0, (a, b) => a + b),
              radius: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
                if (email.isNotEmpty)
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'OpenSans',
                          fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: Colors.white54,
              fontFamily: 'OpenSans',
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontSize: 12)),
    );
  }

  Widget _group(List<Widget> rows) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
          color: _groupColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 52, color: Colors.white12),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String title,
      {String? value,
      String? hint,
      bool chevron = false,
      bool danger = false,
      VoidCallback? onTap}) {
    final color = danger ? Colors.redAccent : Colors.white;
    final row = InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  color: danger ? Colors.redAccent : Colors.white70, size: 22),
              const SizedBox(width: 16),
              Text(title,
                  style: TextStyle(
                      color: color, fontFamily: 'OpenSans', fontSize: 16)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value ?? '',
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'OpenSans',
                        fontSize: 15)),
              ),
              if (chevron)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.chevron_right, color: Colors.white38),
                ),
            ],
          ),
        ),
      ),
    );
    return hint == null ? row : Tooltip(message: hint, child: row);
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (e) {
      debugPrint('open $uri: $e');
    }
    messenger?.showSnackBar(const SnackBar(content: Text("Couldn't open it")));
  }

  Future<void> _changePassword(BuildContext context, String email) async {
    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _groupColor,
        title: const Text('Change password',
            style: TextStyle(color: Colors.white)),
        content: Text("We'll email a link to $email to set a new password.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white70))),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send link',
                  style: TextStyle(
                      color: Colors.amberAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (send != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      messenger?.showSnackBar(
          SnackBar(content: Text('Check $email for the reset link')));
    } catch (e) {
      debugPrint('reset email: $e');
      messenger?.showSnackBar(
          const SnackBar(content: Text("Couldn't send the email. Try again.")));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: _groupColor,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Log out of Chuckler?',
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'OpenSans',
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Log out',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
    if (yes == true && context.mounted) await signOut(context, auth: auth);
  }
}
