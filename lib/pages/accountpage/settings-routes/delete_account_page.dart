import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../state/sign_out.dart';

/// Settings > Delete account. Firebase only deletes an account that signed
/// in recently, so the user confirms with their password first. Deleting
/// the Auth account starts onAccountDeleted (functions/account.js), which
/// removes their data.
class DeleteAccountPage extends StatefulWidget {
  /// for tests; the real FirebaseAuth otherwise
  final FirebaseAuth? auth;

  const DeleteAccountPage({super.key, this.auth});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _password = TextEditingController();
  bool _working = false;
  String? _error;

  FirebaseAuth get _auth => widget.auth ?? FirebaseAuth.instance;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      setState(() => _error = 'Sign in again, then try once more.');
      return;
    }
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: _password.text));
      await user.delete();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _working = false;
        _error = switch (e.code) {
          'wrong-password' ||
          'invalid-credential' ||
          'invalid-login-credentials' =>
            "That password isn't right.",
          'too-many-requests' => 'Too many tries. Wait a bit and try again.',
          'network-request-failed' => "You're offline. Try again.",
          _ => "Couldn't delete your account. Try again.",
        };
      });
      return;
    } catch (e) {
      debugPrint('delete account: $e');
      setState(() {
        _working = false;
        _error = "Couldn't delete your account. Try again.";
      });
      return;
    }
    if (!mounted) return;
    await signOut(context, auth: _auth, alreadySignedOut: true);
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _password.text.isNotEmpty && !_working;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Delete account',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            const Text('This deletes your account for good.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'OpenSans',
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
            const SizedBox(height: 16),
            for (final line in const [
              'Your profile, stats, awards and streak',
              'Your answers, their comments and matchups',
              'Your friend prompts, friends and requests',
              'Comments you left on other answers',
              'Your username, which someone else can then take',
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(line,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'OpenSans',
                              fontSize: 15)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            const Text("This can't be undone.",
                style: TextStyle(
                    color: Colors.white54,
                    fontFamily: 'OpenSans',
                    fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              enabled: !_working,
              onChanged: (_) => setState(() => _error = null),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Your password',
                labelStyle: const TextStyle(color: Colors.white54),
                errorText: _error,
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: canDelete ? _delete : null,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                disabledBackgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _working
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Delete my account',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            TextButton(
              onPressed: _working ? null : () => Navigator.of(context).pop(),
              child: const Text('Keep my account',
                  style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
