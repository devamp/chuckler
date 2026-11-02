import 'package:auto_size_text/auto_size_text.dart';
import 'package:chuckler/CustomReusableWidgets/custom_buttons.dart';
import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:chuckler/pages/feedpage/comment_form.dart';
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

class MatchupTemplate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return new DecoratedBox(
        decoration: BoxDecoration(),
        child: Column(children: [
          Container(
            padding: EdgeInsets.fromLTRB(10, 20, 0, 0),
            child: Text(
              "This is where the prompt will go this is where the prompt will go _______. ",
              style: TextStyle(
                  fontFamily: "OpenSans",
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700),
              textAlign: TextAlign.left,
            ),
          ),
          Column(
            children: [
              UserMatchAnswer(),
              UserMatchAnswer(),
            ],
          ),
          Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Row(
                children: [
                  Container(
                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      constraints: BoxConstraints(
                          minWidth: screenWidth / 9, maxWidth: screenWidth / 9),
                      child: ProfilePhoto(
                        username: "Test",
                        img: "",
                        radius: 15,
                      )),
                  Container(
                      constraints: BoxConstraints(maxWidth: screenWidth / 1.5),
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Center(
                              child: Text(
                            "This is where the description for the prompt will go  ",
                            style: TextStyle(fontSize: 12, color: Colors.white),
                            textAlign: TextAlign.center,
                          )))),
                  Container(
                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      constraints: BoxConstraints(
                          minWidth: screenWidth / 9, maxWidth: screenWidth / 9),
                      child: IconButton(
                        icon: Icon(
                          Icons.chat_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          showModalBottomSheet(context: context, builder:(BuildContext context) {

                            return Container(
                              width: screenWidth,
                              alignment: Alignment.bottomCenter,
                              height: screenHeight,
                              color: Colors.black,
                              child: CommentForm( screenHeight: screenHeight, screenWidth: screenWidth,)
                            );
                          }

                          );
                        },
                      )),
                ],
              )),
          Divider(
            thickness: 2,
            color: Colors.blueGrey,
          )
        ]));
  }
}

class UserMatchAnswer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                  minWidth: screenWidth / 8, maxWidth: screenWidth / 8),
            ),
            Container(
                constraints: BoxConstraints(
                    minWidth: screenWidth / 9, maxWidth: screenWidth / 9),
                child: ProfilePhoto(
                  username: "Test",
                  img: "",
                  radius: 14,
                )),
            Container(
              constraints: BoxConstraints(minWidth: screenWidth / 1.85),
              child:
                  Text("USERNAME", style: TextStyle(color: Color(0xfffbd0bf))),
            ),
            Container(
                alignment: Alignment.bottomCenter,
                constraints: BoxConstraints(
                    minWidth: screenWidth / 8, maxWidth: screenWidth / 8),
                child: IconButton(
                  alignment: Alignment.bottomCenter,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    size: screenWidth / 20,
                    Icons.favorite,
                    color: Color(0xfffbd0bf),
                  ),
                  onPressed: () {},
                )),
          ],
        ),
        Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    minWidth: screenWidth / 4, maxWidth: screenWidth / 4),
              ),
              Container(
                  alignment: Alignment.topCenter,
                  constraints: BoxConstraints(
                      minWidth: screenWidth / 1.7, maxWidth: screenWidth / 1.7),
                  child: Text(
                    "Answer one here fgsfasggfsfhhdf fhhdffhdhhsdffhfhfh",
                    style: TextStyle(fontSize: 14),
                  ))
            ]),
      ],
    );
  }
}
