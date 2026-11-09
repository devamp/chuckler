import 'package:auto_size_text/auto_size_text.dart';
import 'package:chuckler/CustomReusableWidgets/custom_buttons.dart';
import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:chuckler/data/users.dart';
import 'package:chuckler/data/posts.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:chuckler/state/prompt_service.dart';
import 'package:chuckler/state/feed_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../database/models.dart';
import '../../database/isarDB.dart';
import 'feedpage_modal.dart';
import 'feedpage_promptarea.dart';
import 'package:chuckler/CustomReusableWidgets/custom_text_widgets.dart';
import 'no_user_post.dart';
import 'matchup.dart';
import 'feedpage_vote.dart';
import 'matchup_filter.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  //TODO REPLACE WITH DYNAMIC DATA
  final havePosted = true;

  //false shows swipe voting, true shows past responses
  bool showPast = false;

  /// The Vote | Past toggle. Off for the first release.
  static const bool showPastToggle = false;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color.fromRGBO(9, 32, 63, 1),
              Color.fromRGBO(83, 120, 149, 1),
              Colors.black,
            ],
            center: Alignment(0.6, 0.5),
            radius: 2,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    const MatchupFilterButton(),
                    const Spacer(),
                    // The Past view is hidden for the first release; the
                    // toggle and CreateForm stay for later.
                    if (showPastToggle) voteOrPastToggle(),
                  ],
                ),
              ),
              Expanded(
                  child: !showPast
                      ? const VotePage()
                      : havePosted
                          ? const CreateForm()
                          : const NoUserPost())
            ],
          ),
        ));
  }

  Widget voteOrPastToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 16, 6),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          toggleOption('Vote', !showPast, () => setState(() => showPast = false)),
          toggleOption('Past', showPast, () => setState(() => showPast = true)),
        ],
      ),
    );
  }

  Widget toggleOption(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? Colors.amberAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontFamily: 'OpenSans',
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
    );
  }
}

class CreateForm extends StatelessWidget {
  const CreateForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[Expanded(flex: 30, child: FeedPageContent())],
    );
  }
}

class FeedPageContent extends StatelessWidget {
  FeedPageContent({super.key});

  final List<MaterialAccentColor> userColors = [
    Colors.greenAccent,
    Colors.purpleAccent
  ];

  /*get the prompts from local db*/
  Future<void> getNextTwoPosts(context) async {
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    //Access the prompt and feed services
    PromptService promptService = Provider.of<PromptService>(context, listen: false);
    FeedService feedService = Provider.of<FeedService>(context, listen: false);
    IsarService isarService = Provider.of<IsarService>(context, listen: false);
    List<DbPost> posts = await isarService.getTwoUnseenPosts();

    if (posts.isEmpty ?? true) {
      print("Getting posts from firebase ");

      //add to the session
      var getRand = promptService.prompts!.length;
      Random r = Random();
      getRand = r.nextInt(getRand);
      var i = 0;
      List<DbPost> postsFromDb = List<DbPost>.empty(growable: true);
      for (DbPrompt p in promptService.prompts!) {
        if (i == getRand) {
          postsFromDb = await getPosts(firestore, p.promptId!, p.promptDateId!);
          await isarService.addPostsToDB(postsFromDb);
          posts = await isarService.getTwoUnseenPosts();
          print("set posts");
          break;
        }
        i++;
      }
    }
    feedService.setCurrentFeedPromptId(posts.first.promptId!);
    feedService.setCurrentPosts(posts);
  }

  /*Get the user information for the modal*/
  Future<DbUser?> getModalUser(context, String uid) async {
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    IsarService isarService = Provider.of<IsarService>(context, listen: false);
    SessionService sessionService = Provider.of<SessionService>(context, listen: false);
    DbUser? user = await isarService.getUserFromDb(uid);
    user ??= await getAUser(firestore, uid);
    if (user != null) {
      if (sessionService.loggedInUser!.friends.isNotEmpty) {
        if (sessionService.loggedInUser!.friends.contains(user.uid!)) {
          user.friend = true;
        }
      }
      if (sessionService.loggedInUser!.pendingFriends.isNotEmpty) {
        if (sessionService.loggedInUser!.pendingFriends.contains(user.uid!)) {
          user.pendingFriend = true;
        }
      }
      isarService.addUserToDb(user);
    }
    return user;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    FeedService feedService = Provider.of<FeedService>(context, listen: true);
    print(feedService.currentPosts!.length);
    print("Rebuilding");
    return Container(
      width: screenWidth/1.1,
        decoration: BoxDecoration(color: Colors.black54),
        child: ListView.builder(
          shrinkWrap: true,
        itemCount: 5,
        itemBuilder: (context, index) {
          return  MatchupTemplate();
        }));
  }
}

/** DROP DOWN MENU (old, unused: replaced by MatchupFilterButton) */
class DropdownButtonExample extends StatefulWidget {
  const DropdownButtonExample({super.key});

  @override
  State<DropdownButtonExample> createState() => _DropdownButtonExampleState();
}

class _DropdownButtonExampleState extends State<DropdownButtonExample> {
  static List<String> list = <String>['Global', 'Local', 'Friends', 'Create+'];
  String dropdownValue = list.first;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black,),
      underline: Container(),
      dropdownColor: Colors.white70,
      style: const TextStyle(color: Colors.black, fontSize: 20),
      padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
      onChanged: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
        });
      },
      items: list.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
