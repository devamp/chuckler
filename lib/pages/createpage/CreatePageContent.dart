// ignore_for_file: unused_local_variable
import 'package:chuckler/data/posts.dart';
import 'package:chuckler/data/users.dart';
import 'package:chuckler/data/prompts.dart';
import 'package:chuckler/pages/createpage/create_page_loadingbar.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chuckler/pages/loginpage/login_page.dart';
import 'package:chuckler/PageTransitioner.dart';
import 'package:flutter/widgets.dart';
import '../../Session.dart';
import 'package:provider/provider.dart';
import '../../database/isarDB.dart';
import '../../database/models.dart';
import 'package:chuckler/CustomReusableWidgets/custom_buttons.dart';
import 'prompt_identifier.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:chuckler/pages/createpage/create_page_middle.dart';
import '../constant_strings.dart';

class CreatePageContent extends StatefulWidget {
  const CreatePageContent({super.key});

  @override
  _CreatePageContentState createState() => _CreatePageContentState();
}

class _CreatePageContentState extends State<CreatePageContent>
    with WidgetsBindingObserver {
  final TextEditingController _controller =
      TextEditingController(text: CreatePageTextPrompt);

//state variables
  bool isUser = false;
  String userId = "";
  String userName = "";
  String promptId = "";
  String promtDateId = "";
  String timeRemaining = "";
  List<bool> canPost = List.empty(growable: true);
  List<String> textControllerStates = List.empty(growable: true);
  var promptVal = 0;
  FocusNode focusNode = FocusNode();
  bool keyBoardOut = false;

  /*
  This Function sends the post to the data base with the current text
   */
  Future<void> postData() async {
    //check if user can post
    UserService userSession = Provider.of<UserService>(context, listen: false);
    //no posting until today's prompt is published
    if (isAwaitingPrompt(userSession.prompts![promptVal])) {
      return;
    }
    if (canPost[promptVal] &&
        userSession.userPostsForPrompts[promptVal] == null) {
      canPost[promptVal] = false;
      //check if user has already posted
      FirebaseFirestore firebase =
          Provider.of<FirebaseFirestore>(context, listen: false);

      try {
        //Retrieve newly created post
        DbPost justPosted = await createPost(
            firebase,
            userSession.loggedInUser!,
            userSession.prompts![promptVal],
            _controller.text);
        //Add post to local DB
        IsarService isar = Provider.of<IsarService>(context, listen: false);
        //Incrament user posts stat
        isar.addOnePostToDB(justPosted);
        incrementNumPosts(firebase, userId);
        userSession.userPostsForPrompts[promptVal] = justPosted;
      } catch (error) {
        print("Error: $error");
      }
      return;
    }
  }

  /*
  This function ensures the user is logged in and establishes the userId
   */
  Future<bool> checkIfUserIsLoggedIn() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in
      userId = user.uid;
      return true;
    } else {
      // User is not logged in
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    UserService userSession = Provider.of<UserService>(context, listen: false);
    if (userSession.userPostsForPrompts.first != null) {
      _controller.text = userSession.userPostsForPrompts.first!.answer!;
    }
    //Set up text box
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        if (_controller.text.trim().isEmpty) {
          _controller.text = CreatePageTextPrompt;
        }
      }
      setState(() {});
    });
    //Ensure user is logged in
    checkTheUser();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  /*
  Sets the isUser state to true if the user is logged in and false if the user is not logged int
   */
  Future<void> checkTheUser() async {
    bool theUs = await checkIfUserIsLoggedIn();
    setState(() {
      isUser = theUs;
    });
  }

  @override
  Widget build(BuildContext context) {
    //Set variables
    UserService userSession = Provider.of<UserService>(context, listen: false);
    userName = userSession.loggedInUser!.username!;
    double screenWidth = MediaQuery.sizeOf(context).width;
    double screenHeight = MediaQuery.sizeOf(context).height;
    List<DbPrompt> prompts = userSession.prompts!;
    promptId = prompts[promptVal].promptId!;
    promtDateId = prompts[promptVal].promptDateId!;
    for (int i = 0; i < userSession.prompts!.length; i++) {
      canPost.add(true);
      if (userSession.userPostsForPrompts[i] == null) {
        textControllerStates.add(CreatePageTextPrompt);
      } else {
        if (textControllerStates.length >= prompts.length) {
          textControllerStates[i] = userSession.userPostsForPrompts[i]!.answer!;
        } else {
          textControllerStates.add(userSession.userPostsForPrompts[i]!.answer!);
        }
      }
    }
    return Column(
      children: [
        //Prompt Area
        Expanded(
            flex: 50,
            child: Container(
              constraints: BoxConstraints.tight(
                  Size(screenWidth / 1.1, double.infinity)),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black26, width: 5)),
              child: Column(children: [
                Expanded(flex: 1, child: Container()),
                Expanded(
                    flex: 6,
                    child: Row(children: [
                      Expanded(flex: 1, child: Container()),
                      Expanded(flex: 4, child: PromptIdentifier()),
                      Expanded(
                          flex: 2,
                          child: IconButton(
                            icon: Icon(
                              Icons.public,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () {
                              Dialog(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: FittedBox(
                                          alignment: Alignment.center,
                                          child: Container(
                                              padding: EdgeInsets.all(12),
                                              constraints: BoxConstraints(
                                                  maxWidth: screenWidth / 1.2,
                                                  maxHeight: screenHeight / 4),
                                              child: Text(
                                                LikeDislikeInfoText,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              )))));
                            },
                          )),
                    ])),
                Expanded(
                    flex: 20,
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                        child: Center(
                            child: AutoSizeText.rich(
                          TextSpan(
                            style: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                                fontFamily: 'OpenSans',
                                fontWeight: FontWeight.normal),
                            children: <TextSpan>[
                              TextSpan(text: prompts[promptVal].before),
                              TextSpan(
                                  text: _controller.text,
                                  style: const TextStyle(
                                      color: Color(0xfffbd0bf))),
                              //Color(0xff84C3D1)
                              TextSpan(text: prompts[promptVal].after),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 10,
                          minFontSize: 2,
                        )))),
                Divider(
                  color: Colors.black12,
                  thickness: 3,
                ),
                Expanded(
                    flex: 6,
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                              flex: 2,
                              child: promptVal > 0
                                  ? IconButton(
                                      alignment: Alignment.center,
                                      onPressed: () {
                                        textControllerStates[promptVal] =
                                            _controller.text;
                                        if ((promptVal - 1) >= 0) {
                                          setState(() {
                                            promptVal = promptVal - 1;
                                            _controller.text =
                                                textControllerStates[promptVal];
                                          });
                                        }
                                      },
                                      splashRadius: 10,
                                      icon: const Icon(
                                        Icons.chevron_left_outlined,
                                        color: Color(0xff84C3D1),
                                      ),
                                    )
                                  : Container()),
                          Expanded(
                              flex: 10,
                              child: CreatePageLoadingBar(
                                  pVal: promptVal, friend: null)),
                          //PROMPT W/ USER ANSWER
                          Expanded(
                              flex: 2,
                              child: (promptVal < prompts.length - 1)
                                  ? IconButton(
                                      alignment: Alignment.center,
                                      onPressed: () {
                                        textControllerStates[promptVal] =
                                            _controller.text;
                                        if ((promptVal + 1) < prompts.length) {
                                          setState(() {
                                            promptVal++;
                                            _controller.text =
                                                textControllerStates[promptVal];
                                          });
                                        }
                                      },
                                      splashRadius: 10,
                                      icon: const Icon(
                                        Icons.chevron_right_outlined,
                                        color: Color(0xff84C3D1),
                                      ),
                                    )
                                  : Container()),
                        ])),
                Expanded(flex: 1, child: Container())
              ]),
            )),
        !focusNode.hasFocus
            ? Expanded(
                flex: 12,
                child: Container(
                  alignment: Alignment.center,
                  child:  CreateMiddle(),
                ),
              )
            : Expanded(flex: 1, child: Container()),
        Expanded(
            flex: 25,
            child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                    constraints: BoxConstraints.tight(
                        Size(double.infinity, screenHeight / 3)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: Container()),
//Text Box Container - INPUT
                          Expanded(
                            flex: 30,
                            child: Column(children: [
                              KeyboardVisibilityBuilder(
                                  builder: (context, isKeyboardVisible) {
                                if (isKeyboardVisible == true) {
                                  keyBoardOut = true;
                                }
                                if (!isKeyboardVisible && keyBoardOut) {
                                  keyBoardOut = false;
                                  focusNode.unfocus();
                                }
                                return TextField(
                                  textInputAction: TextInputAction.go,
                                  controller: _controller,
                                  onEditingComplete: () {
                                    print("This happened");
                                    focusNode.unfocus();
                                  },
                                  onTap: () {
                                    if (_controller.text.trim() ==
                                        CreatePageTextPrompt) {
                                      _controller.text = "";
                                      setState(() {});
                                    }
                                  },
                                  onTapOutside: (pointer) {
                                    focusNode.unfocus();
                                  },
                                  onChanged: (text) {
                                    setState(() {});
                                  },
                                  maxLines: 4,
                                  minLines: 1,
                                  maxLength: 500,
                                  keyboardType: TextInputType.multiline,
                                  cursorColor: Colors.black,
                                  focusNode: focusNode,
                                  style: TextStyle(
                                      color: Color(0xfffbd0bf), fontSize: 18),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.black54,
                                    constraints: BoxConstraints(
                                      maxWidth: screenWidth / 1.5,
                                    ),
                                    hintText: CreatePageTextPrompt,
                                    counterStyle:
                                        TextStyle(color: Colors.white54),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black54,
                                        // Unfocused border color
                                        width: 2.0, // Unfocused border weight
                                      ),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black87, width: 3)),
                                    contentPadding: const EdgeInsets.all(10),
                                  ),
                                );
                              }),
                              Container(
//Row For the Post Button
                                  child: ElevatedIconButton(
                                      color: Colors.black87,
                                      iconColor: Colors.blueGrey,
                                      fractionHeight: 40,
                                      text: "Post",
                                      width: screenWidth / 3,
                                      onPressed: () {
                                        if (isUser) {
                                          //Uncomment below to post data
                                          postData();
                                        } else {
                                          // User is not logged in
                                          // Show a dialog and offer to take the user back to the login screen
                                          showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                    title: const Text(
                                                        'Not Logged In'),
                                                    content: const Text(
                                                        'You cannot post unless you are logged in.'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        child: const Text(
                                                            'Go to Login'),
                                                        onPressed: () {
                                                          Navigator.push(
                                                              context,
                                                              SmoothPageTransition(
                                                                child:
                                                                    LoginPage(),
                                                              ));
                                                        },
                                                      )
                                                    ]);
                                              });
                                        }
                                      }))
                            ]),
                          )
                        ])))),
      ],
    );
  }
}
//Color(0xff84C3D1)
