import 'package:flutter/material.dart';
import 'package:flutter_profile_picture/flutter_profile_picture.dart';
import 'package:flutter_svg/svg.dart';

/// ProfilePicture builds initials from the space-separated words of a name
/// and throws a RangeError on an empty word, so strip leading, trailing and
/// repeated spaces before passing a name to it.
String profilePictureName(String name) {
  return name.trim().split(RegExp(r'\s+')).join(' ');
}

class ProfilePhoto extends StatelessWidget {
  final String username;
  final String? img;
  final double radius;

  const ProfilePhoto(
      {super.key,
      required this.username,
      required this.img,
      required this.radius});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Center(
          child: img == ""
              ? ProfilePicture(
                  name: profilePictureName(username),
                  radius: radius,
                  fontsize: (radius * 0.9),
                )
              : Container(
                  width: radius * 2,
                  height: radius * 2,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.cover, // Adjust as needed
                      image: NetworkImage(
                          img!), // Use NetworkImage for network image
                    ),
                  ))),

      ///TODO LOGIC FOR COLOR / SHOW IF STATUS ATTAINED ONLY
      Positioned(
        right: 0,
        left: radius,
        bottom: 0,
        child: Container(
          decoration: const BoxDecoration(
              color: Colors.amberAccent, shape: BoxShape.circle),
        ),
      )
    ]);
  }
}
