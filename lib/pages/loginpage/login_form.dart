import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/prompts.dart';
import '../../data/users.dart';
import '../../data/posts.dart';
import '../../Session.dart';
import '../../database/isarDB.dart';
import '../../database/models.dart';
import '../../db.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  String resetEmail = '';

  /// Get the initial posts
  Future<bool> verifyLogin(email, password, context) async {
    User user;
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      user = result.user!;
      await setupUserSession(context, user.uid);
      return true;
    } catch (e) {
      print('THIS IS WHERE THE ERROR IS $email, $password Error: $e');
      return false;
    }
  }

  Future<void> getInitialPosts(context, FirebaseFirestore firestore,
      String prmtId, String prmtDateId) async {
    //instance of usersession
    final UserService userSession =
        Provider.of<UserService>(context, listen: false);
    final isarService = Provider.of<IsarService>(context, listen: false);
    //check if posts are in local database
    List<DbPost> posts = await isarService.getTwoUnseenPosts();

    //get new posts from firebase if none exist in DB
    if (posts.isEmpty) {
      print("running firebase retrieval");
      posts = await getPosts(firestore, prmtId, prmtDateId);

      await isarService.addPostsToDB(posts);
      userSession.setCurrentPosts(await isarService.getTwoUnseenPosts());
    } else {
      userSession.setCurrentPosts(posts);
    }
  }

  Future<void> setupUserSession(context, userId) async {
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    print(userId + "This is the userID");
    final UserService userSession =
        Provider.of<UserService>(context, listen: false);
    final isarService = Provider.of<IsarService>(context, listen: false);

    try {
      List<DbPrompt> promptsToAdd = List<DbPrompt>.empty(growable: true);
      promptsToAdd = await isarService.getDailyPromptsFromDB();
      //check if user has already logged in
      if (promptsToAdd.isEmpty) {
        //if so get stored prompts
        promptsToAdd = await getDailyPrompts(firestore);
        if (promptsToAdd.isNotEmpty) {
          print("getting prompts from db");
          isarService.addPromptsToDB(promptsToAdd);
        }
      }
      if (promptsToAdd.isEmpty) {
        //TODO ADD SOMETHING TO HANDLE IF NOTHING IS IN THE DB
      }
      //add to the session
      var getRand = promptsToAdd.length;
      Random r = Random();
      getRand = r.nextInt(getRand);
      print("randomnum");
      print(getRand);
      var i = 0;
      for (DbPrompt p in promptsToAdd) {
        if (i == getRand) {
          userSession.setCurrentFeedPromptId(p.promptId!);
          await getInitialPosts(
              context, firestore, p.promptId!, p.promptDateId!);
        }
        userSession.addPrompt(p);
        ///TODO get posts from DB first...Not good for testing
        userSession.addPostForPrompt(await getUserPostForPrompt(firestore, userId, p.promptDateId!, p.promptId!));
        i++;
      }

      DbUser? theUser = await getLoggedInUserInfo(firestore, userId);
      if (theUser != null) {
        userSession.setLoggedInUser(theUser);
      }
      String? lTime = await getCachedLoginTime();
      userSession.setLoginTime(lTime);
      if (!userSession.firstLogin) {
        print("last login ${userSession.logTime!}");
      }
      cacheLoginTime();
    } catch (e) {
      print('Error: $e');
    }
  }

  void showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Reset Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 10),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.lock,
                    size: 52, // Adjust the size as needed
                    color: Color(0xFFffd230),
                  ),
                ),

                const SizedBox(
                    height:
                        20), // Adjust the spacing between logo and other content

                const Text(
                  'Enter your email and we will send you a rest link',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  cursorColor: Colors.white,
                  onChanged: (text) {
                    resetEmail = text;
                  },
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: "Email",
                    hintStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _auth.sendPasswordResetEmail(email: resetEmail);
                    } catch (e) {
                      print(e);
                    }
                    Navigator.pop(context);
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all<Color>(const Color(0xFFffd230)),
                    foregroundColor:
                        WidgetStateProperty.all<Color>(Colors.black),
                    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                        const EdgeInsets.all(10.0)),
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  ),
                  child: const Text('Submit Request'),
                ),
                const SizedBox(
                  height: 20,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        TextField(
          cursorColor: Colors.white,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            hintText: "Email",
            hintStyle: const TextStyle(color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          cursorColor: Colors.white,
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          // for password
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            hintText: "Password",
            hintStyle: const TextStyle(color: Colors.white),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: const BorderSide(color: Colors.black, width: 1.0)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0),
              borderSide: const BorderSide(
                color: Colors.black,
                width: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            showForgotPasswordSheet(context);
          },
          child: Container(
            padding: const EdgeInsets.only(left: 10.0),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                    const Color.fromARGB(255, 75, 75, 75)),
                foregroundColor:
                    WidgetStateProperty.all<Color>(const Color(0xFFffd230)),
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 10.0)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_add),
                  SizedBox(width: 8.0),
                  Text('Sign Up'),
                ],
              ),
            ),
            const SizedBox(width: 15),
            ElevatedButton(
              onPressed: () async {
                if (isLoading.value) {
                  return;
                }
                isLoading.value = true;
                String email = _emailController.text.trim();
                String password = _passwordController.text.trim();
                bool status = await verifyLogin(email, password, context);
                isLoading.value = false;
                if (status) {
                  Navigator.pushReplacementNamed(context, '/app');
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Verification Failed"),
                        content: const Text(
                            "Invalid email or password. Please try again."),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Colors.black),
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                    const EdgeInsets.fromLTRB(18.0, 10.0, 18.0, 10.0)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              child: ValueListenableBuilder(
                valueListenable: isLoading,
                builder: (context, value, child) {
                  return value
                      ? const CircularProgressIndicator(
                          color: Colors.amber,
                        )
                      : child!;
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_sharp),
                    SizedBox(width: 8.0),
                    Text('Login'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
