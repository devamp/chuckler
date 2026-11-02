import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:provider/provider.dart';
import '../../../state/session_service.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  Widget buildAccountSettingOption(
      IconData titleIcon, title, String data, IconData arrowIcon) {
    return GestureDetector(
      onTap: () {
        print('tapped');
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0, top: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(titleIcon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              title ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              data,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Icon(arrowIcon, color: Colors.white)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SessionService sessionService = Provider.of<SessionService>(context, listen: true);
    String username = sessionService.loggedInUser!.username!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Account'),
        titleTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 22),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(
              bottom: 50.0, left: 10.0, right: 10.0, top: 10),
          child: Column(
            children: [
              ProfilePicture(name: profilePictureName(username), radius: 50, fontsize: 20),
              const SizedBox(height: 10),
              const Text(
                'Change photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              buildAccountSettingOption(Icons.person, 'Username',
                  sessionService.loggedInUser!.username!, Icons.chevron_right),
              buildAccountSettingOption(Icons.email, 'Email',
                  'exampleuser@gmail.com', Icons.chevron_right),
              buildAccountSettingOption(
                  Icons.key, 'Password', '', Icons.chevron_right),
              buildAccountSettingOption(Icons.notifications, 'Notifications',
                  'On', Icons.chevron_right),
              const SizedBox(height: 25),
              Spacer(),
              GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: Colors.white,
                          title: Text(
                            'Are you sure?',
                            style: TextStyle(color: Colors.black),
                          ),
                          content: Text(
                            'This action is irreversible. Your account will be deleted forever.',
                            style: TextStyle(color: Colors.red),
                          ),
                          actions: <Widget>[
                            TextButton(
                              child: Text(
                                'Deactivate',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text(
                                'Keep Account',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.heart_broken, color: Colors.white),
                        const SizedBox(width: 10),
                        const Text(
                          'Deactivate Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
