// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/moderation.dart';
import '../../data/users.dart';
import '../constant_strings.dart';
class SignupPage extends StatefulWidget {
  @override
  SignupPage({super.key});

  @override
  _SignupState createState() => _SignupState();
}
// ignore: must_be_immutable
class _SignupState extends State<SignupPage> {
  String username = '';
  String email = '';
  String password = '';
  int age = 18;
  bool agreed = false;
  ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: const Color(0xFFffd230),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "BECOME A CHUCKLER",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.only(left: 10.0),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 5.0,
                      ),
                    ),
                    child: const Center(
                      child: CircleAvatar(
                        radius: 150,
                        backgroundColor: Colors.transparent,
                        backgroundImage:
                            AssetImage('assets/Chuckler-logo-circle.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    onChanged: (text) {
                      //keyboard suggestions leave a trailing space
                      username = text.trim();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: "Username",
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
                    onChanged: (text) {
                      email = text;
                    },
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
                    onChanged: (text) {
                      password = text;
                    },
                    obscureText: true, // for password
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.black,
                      hintText: "Password",
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
                  const SizedBox(height: 20),
                  SliderWidget(
                    onSliderValueChanged: (value) {
                      age = value;
                    },
                  ),
                  // App Store guideline 1.2: users agree to terms that rule
                  // out objectionable content
                  CheckboxListTile(
                    value: agreed,
                    onChanged: (v) => setState(() => agreed = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.amberAccent,
                    checkColor: Colors.black,
                    contentPadding: EdgeInsets.zero,
                    title: GestureDetector(
                      onTap: termsUrl.isEmpty
                          ? null
                          : () => launchUrl(Uri.parse(termsUrl),
                              mode: LaunchMode.externalApplication),
                      child: Text(
                        "I agree to the${termsUrl.isEmpty ? '' : ' (tap to read)'} Terms and won't post objectionable or abusive content.",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () async {
                        if(isLoading.value){return;}
                        isLoading.value = true;
                        //Register User if it is valid information
                        if (!agreed) {
                          isLoading.value = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Agree to the Terms to make an account.')));
                          return;
                        }
                        if (username.isNotEmpty &&
                            email.isNotEmpty &&
                            password.isNotEmpty) {
                          try {
                            if (!validUsername.hasMatch(username)) {
                              throw Exception(
                                  '] Usernames are 3 to 20 letters, numbers, dots or underscores.');
                            }
                            // no slurs or explicit words in usernames, which
                            // everyone sees (leaderboards, comments)
                            final words = wordsIn(await loadWordList());
                            if (containsBlockedWords(username, words)) {
                              throw Exception('] $blockedUsernameMessage');
                            }
                            UserCredential result =
                                await _auth.createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            try {
                              // claims the username; fails if it's taken
                              await registerNewUser(firestore,
                                  result.user!.uid, username, age);
                            } catch (e) {
                              // give the email back so they can try again
                              await result.user!.delete();
                              throw Exception('] $e');
                            }
                            isLoading.value = false;
                            // ignore: use_build_context_synchronously
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.amber,
                                  title: Text('Success'),
                                  content: Text(
                                      'Please log in with your new credentials.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        // back to the login screen, the
                                        // only route under signup
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                                '/', (_) => false);
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } catch (e) {
                            isLoading.value = false;
                            String errorMessage = e.toString();
                            int startIndex = errorMessage.indexOf(']');
                            String endMessage =
                                errorMessage.substring(startIndex + 1).trim();

                            // ignore: use_build_context_synchronously
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Failure'),
                                  content: Text(endMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('Try Again'),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        } else {
                          print('Please fill in all fields');
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStateProperty.all<Color>(Colors.black),
                        foregroundColor:
                            WidgetStateProperty.all<Color>(Colors.white),
                        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
                            const EdgeInsets.all(10.0)),
                        shape:
                            WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                      ),
                      // ignore: prefer_const_constructors
                      child: ValueListenableBuilder(
                        valueListenable: isLoading,
                        builder: (context, value, child) {
                          return value ? CircularProgressIndicator() : child!;
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.app_registration_rounded),
                                SizedBox(width: 8.0),
                                Text(
                                  'Register Account',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 15.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .pushNamedAndRemoveUntil('/', (_) => false);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      alignment: Alignment.center,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.black,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                                text: 'Already have an account?',
                                style: TextStyle(fontSize: 18)),
                            TextSpan(
                                text: ' Login Here',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SliderWidget extends StatefulWidget {
  const SliderWidget({super.key, required this.onSliderValueChanged});

  final void Function(int) onSliderValueChanged;

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  int _sliderValue = 18;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'SELECT YOUR AGE: $_sliderValue',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: _sliderValue.toDouble(),
          onChanged: (value) {
            setState(() {
              _sliderValue = value.toInt();
            });
            widget.onSliderValueChanged(_sliderValue);
          },
          min: 13,
          max: 100,
          divisions: 100,
          label: '$_sliderValue',
          activeColor: Colors.black,
          inactiveColor: Colors.white,
          thumbColor: const Color(0xFFffd230),
        ),
      ],
    );
  }
}
