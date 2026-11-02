import 'package:flutter/material.dart';
import 'package:chuckler/database/models.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../state/session_service.dart';

class AccountPosts extends StatelessWidget {
  final List<DbPost> posts;

  const AccountPosts({super.key, required this.posts});

  @override
  Widget build(context) {
    SessionService sessionService = Provider.of<SessionService>(context, listen: true);
    double screenHeight = MediaQuery.of(context).size.height;

    print('rebuilding');
    return SizedBox(
      height: screenHeight / 2,
      child: posts.isNotEmpty
          ? ListView.builder(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.only(top: 5.0, bottom: 50.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 2), // Shadow position
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ProfilePicture(
                                name: profilePictureName(sessionService.loggedInUser!.username!),
                                radius: 20,
                                fontsize: 20),
                            const SizedBox(width: 10),
                            Text(
                              sessionService.loggedInUser!.username!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'I love this app, this is a post. I hope this post goes viral man I cannot wait!!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: const FaIcon(FontAwesomeIcons.heart,
                                      color: Colors.redAccent),
                                ),
                                const Text(
                                  '123', // Number of likes
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const Icon(Icons.share, color: Colors.white),
                            // Share icon (optional)
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const Text("You haven't posted anything yet"),
    );
  }
}

// class AccountPosts extends StatelessWidget {
//   final List<DbPost> posts;
//
//   const AccountPosts({super.key, required this.posts});
//
//   @override
//   Widget build(context) {
//     double screenHeight = MediaQuery.of(context).size.height;
//     print('rebuilding');
//     return SizedBox(
//         height: screenHeight / 2,
//         child: posts.isNotEmpty
//             ? ListView.builder(
//                 padding: EdgeInsets.symmetric(vertical: 10.0),
//                 itemCount: posts.length,
//                 itemBuilder: (context, index) {
//                   return Column(children: [
//                     SizedBox(
//                       height: 150,
//                       child: Center(
//                           child: Stack(
//                         alignment: Alignment.centerLeft,
//                         children: [
//                           Container(
//                               margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
//                               constraints: const BoxConstraints(maxWidth: 100),
//                               decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(20),
//                                   color: Colors.amberAccent)),
//                           Container(
//                               margin: const EdgeInsets.fromLTRB(40, 0, 0, 0),
//                               decoration:
//                                   const BoxDecoration(color: Colors.black)),
//                           Container(
//                               margin: const EdgeInsets.fromLTRB(50, 0, 0, 0),
//                               child: Text(
//                                 "I love this app omg its so fun to work on this app. I cannot wait to finish this app and post it on the app store and make millions!",
//                                 style: Theme.of(context).textTheme.bodySmall,
//                               ))
//                         ],
//                       )),
//                     ),
//                     index < posts.length - 1
//                         ? const Divider(
//                             color: Colors.transparent,
//                             thickness: 0.2,
//                           )
//                         : const SizedBox(height: 50),
//                   ]);
//                 })
//             : const Text("You haven't posted anything yet"));
//   }
// }
