import 'package:chuckler/pages/accountpage/settings-routes/account-settings.dart';
import 'package:chuckler/pages/accountpage/settings-routes/release-notes-settings.dart';
import 'package:chuckler/pages/accountpage/settings-routes/security-settings.dart';
import 'package:chuckler/pages/accountpage/settings-routes/subscription-settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../state/leaderboard_service.dart';
import '../../state/create_service.dart';
import '../../state/prompt_service.dart';
import '../../state/friends_service.dart';
import '../../state/account_service.dart';
import '../../state/voting_service.dart';

class Settings extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Settings({super.key});

  Widget buildSettingModule(BuildContext context, IconData icon, String title,
      String description, Widget targetPage) {
    return GestureDetector(
      onTap: () => title == 'Logout'
          ? showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 200,
                  padding: EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Are you sure you want to log out?',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              PromptService promptService = Provider.of<PromptService>(context, listen: false);
                              promptService.logout();
                              Provider.of<CreateService>(context, listen: false).logout();
                              Provider.of<VotingService>(context, listen: false).logout();
                              Provider.of<FriendsService>(context, listen: false).logout();
                              Provider.of<AccountService>(context, listen: false).logout();
                              Provider.of<LeaderboardService>(context, listen: false).logout();
                              await _auth.signOut();
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.amberAccent,
                              ),
                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close the modal
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: const Text(
                                'No',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Divider(
                        color: Colors.white,
                        thickness: 1,
                        indent: 150,
                        endIndent: 150,
                      )
                    ],
                  ),
                );
              },
            )
          : Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => targetPage,
              ),
            ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey, // You can change the color
              width: 1.0, // You can adjust the width
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, bottom: 10.0, top: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 45,
              ),
              SizedBox(
                width: 15,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w200,
                          color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          titleTextStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.chevronLeft),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: ListView(
          scrollDirection: Axis.vertical,
          children: [
            buildSettingModule(
                context,
                Icons.person,
                'Account',
                'See information about your account, change username, profile picture',
                const AccountSettingsPage() // Navigate to AccountPage
                ),
            buildSettingModule(
                context,
                Icons.security,
                'Security',
                'Manage your account\'s security, including your email, password, and 2FA',
                const SecuritySettings() // Navigate to SecurityPage
                ),
            buildSettingModule(
                context,
                Icons.payment_outlined,
                'Subscription',
                'View your subscription status, payment overview, renewal, and cancellations.',
                const SubscriptionSettings() // Navigate to SubscriptionPage
                ),
            buildSettingModule(
                context,
                Icons.info_outline_rounded,
                'Release Notes',
                'View latest release notes on Chuckler',
                const ReleaseNotes() // Navigate to ReleaseNotesPage
                ),
            buildSettingModule(
                context,
                Icons.logout,
                'Logout',
                'Log out from this account',
                const ReleaseNotes() // Navigate to ReleaseNotesPage
                )
          ],
        ));
  }
}
