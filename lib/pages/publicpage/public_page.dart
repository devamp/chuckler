import 'package:chuckler/CustomReusableWidgets/alert-dialog.dart';
import 'package:chuckler/pages/publicpage/render_post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AwardContainer extends StatelessWidget {
  final FaIcon awardIcon;
  final String awardText;
  final bool isComplete;
  final String awardDescription;

  const AwardContainer({
    Key? key,
    required this.awardIcon,
    required this.awardText,
    required this.isComplete,
    required this.awardDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      height: 150,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            Color.fromRGBO(9, 32, 63, 1),
            Color.fromRGBO(83, 120, 149, 1),
            Colors.black,
          ],
          center: Alignment(0.6, 0.5),
          radius: 2,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // TODO: show the user's real awards (AwardBadge in
          // account_awards.dart) once friend profiles are live
          IconTheme(
            data: IconThemeData(
                color: isComplete ? Colors.amber : Colors.white, size: 35),
            child: awardIcon,
          ),
          const SizedBox(height: 8),
          Text(awardText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0)),
        ],
      ),
    );
  }
}

class PublicPage extends StatefulWidget {
  final String username;

  const PublicPage({super.key, required this.username});

  @override
  _PublicPageState createState() => _PublicPageState();
}

class _PublicPageState extends State<PublicPage> {
  bool isFollowing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const FaIcon(FontAwesomeIcons.chevronLeft),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        // Make the entire body scrollable
        child: Column(
          children: [
            publicPageHeader(
                context, widget.username, isFollowing, _toggleFollow),
            publicPageBody(context),
          ],
        ),
      ),
    );
  }

  void _toggleFollow() {
    setState(() {
      isFollowing = !isFollowing;
    });
  }
}

Widget publicPageHeader(BuildContext context, String username, bool isFollowing,
    Function toggleFollow) {
  return Container(
    color: Colors.black,
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      children: [
        ProfilePicture(name: profilePictureName(username), radius: 55, fontsize: 20),
        const SizedBox(height: 12),
        Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 15),
        const Row(
          children: [
            Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '3928',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Posts',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(width: 40),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '4.2K',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Friends',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(width: 40),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '3.9M',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Likes',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
            Spacer(),
          ],
        ),
        const SizedBox(
          height: 10,
        ),
        ElevatedButton(
          onPressed: () {
            if (isFollowing) {
              showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return SingleChildScrollView(
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 250, // Set the minimum height here
                        ),
                        decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20)),
                            color: Colors.white12),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Divider(
                                thickness: 4, // Adjust thickness of the divider
                                color: Colors.white,
                                indent: 200.0,
                                endIndent: 200.0, // Divider color
                              ),
                              SizedBox(height: 10),
                              Text(
                                username,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Divider(
                                thickness: 0.5,
                                // Adjust thickness of the divider
                                color: Colors.black, // Divider color
                              ),
                              GestureDetector(
                                onTap: () =>
                                    {toggleFollow(), Navigator.pop(context)},
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Unfollow',
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    const FaIcon(
                                      FontAwesomeIcons.userMinus,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                thickness: 0.5,
                                color: Colors.white12,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Message',
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    const FaIcon(
                                      FontAwesomeIcons.message,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                              Divider(
                                thickness: 0.5,
                                color: Colors.white12,
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Report',
                                      style: TextStyle(
                                          fontSize: 20, color: Colors.red),
                                    ),
                                    const SizedBox(width: 10),
                                    const FaIcon(
                                      FontAwesomeIcons.flag,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  });
            } else {
              // perform follow
              toggleFollow();
            }
          },
          style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll<Color>(Colors.white)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFollowing ? 'Following' : 'Add Friend',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(
                width: 8,
              ),
              FaIcon(
                isFollowing
                    ? FontAwesomeIcons.angleDown
                    : FontAwesomeIcons.userPlus,
                // Default icon when not following
                color: Colors.black,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget publicPageBody(BuildContext context) {
  return Container(
    color: Colors.black,
    child: Center(
      child: Column(
        children: [
          achivementsContainer(context),
          const SizedBox(
            height: 15,
          ),
          postsContainer(context)
        ],
      ),
    ),
  );
}

Widget achivementsContainer(BuildContext context) {
  return const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      SizedBox(
        height: 10,
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: Row(
            children: [
              AwardContainer(
                awardIcon: FaIcon(FontAwesomeIcons.userGroup),
                awardText: '100 Friends',
                isComplete: true,
                awardDescription: 'Make 100 friends.',
              ),
              SizedBox(
                width: 20,
              ),
              AwardContainer(
                awardIcon: FaIcon(
                  FontAwesomeIcons.fire,
                  size: 52,
                ),
                awardText: 'Streaker',
                isComplete: true,
                awardDescription:
                    'Log into your account for 30 consecutive days.',
              ),
              SizedBox(
                width: 20,
              ),
              AwardContainer(
                awardIcon: FaIcon(FontAwesomeIcons.heart),
                awardText: '1000 Likes',
                isComplete: true,
                awardDescription: 'Achieve a total of 1000 likes.',
              ),
              SizedBox(
                width: 20,
              ),
              AwardContainer(
                awardIcon: FaIcon(FontAwesomeIcons.percent),
                awardText: 'The 1%',
                isComplete: true,
                awardDescription: 'Be in the top 1% of posters.',
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget postsContainer(BuildContext context) {
  return const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Text(
          'Featured Posts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            RenderPost(
              postText:
                  "🌟🎉 Check out the new feature! It’s like magic, but with code! 💻✨",
            ),
            RenderPost(
              postText:
                  "😂 Why did the programmer quit? Because they didn’t get arrays! 🖥️😆",
            ),
            RenderPost(
              postText:
                  "🚀 Just launched a new app and it's out of this world! 🌍💫 #TechLife",
            ),
            RenderPost(
              postText:
                  "💡 Idea of the day: Why don’t robots ever get lost? They always follow the right algorithm! 🤖🚀",
            ),
            RenderPost(
              postText:
                  "🎮 Level up! The new game update is here and it's full of surprises! 🕹️🎉 #GamingVibes",
            ),
          ],
        ),
      )
    ],
  );
}
