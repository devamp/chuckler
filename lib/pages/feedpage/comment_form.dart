import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Session.dart';
import 'package:chuckler/database/models.dart';

class CommentForm extends StatefulWidget {
 /// final DbPost cfData;
  final double screenHeight;
  final double screenWidth;
//// required this.cfData,
   CommentForm(
      {super.key,
      required this.screenHeight,
      required this.screenWidth});

  @override
  _CommentFormState createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final myController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _hasInput = false;
  List<DbComment> comments = List<DbComment>.empty(growable: true);

  void getPostComments() async {
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
   //// comments = await getComments(firestore, widget.cfData.postId!);
    if (comments.isEmpty) {
      comments.add(DbComment("", "No comments right now..."));
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getPostComments();
    myController.addListener(_checkInput);
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    myController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  _checkInput() {
    setState(() {
      _hasInput = myController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    UserService userService = Provider.of<UserService>(context, listen: false);
    double screenWidth = MediaQuery.sizeOf(context).width;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(

            height: 15,
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 15),
            width: screenWidth,
            color: Colors.blueGrey,
          ),

      Expanded(
          flex: 3,
          child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return Column(children:[Text(
                  comments[index].comment!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                  Divider(thickness: 0.5, color: Colors.white,)
                ]);
              })),
      Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.bottomCenter,
            padding: EdgeInsets.fromLTRB(0, 30, 0, 30),
              constraints: BoxConstraints(
                  minWidth: screenWidth / 1.5, maxWidth: screenWidth / 1.5),
              //color: Colors.white,
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 15),
                focusNode: _focusNode,
                cursorColor: Colors.white,
                // autofocus: true,
                controller: myController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelStyle: TextStyle(fontSize: 20,
                      color: _focusNode.hasFocus ? Colors.amber : Colors.white),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.amber, width: 2)),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  labelText: 'Add a comment',

                  suffixIcon: _hasInput
                      ? IconButton(
                          splashRadius: 16,
                          splashColor: Colors.black,
                          icon: const Icon(
                            Icons.send,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            FirebaseFirestore firestore =
                                Provider.of<FirebaseFirestore>(context,
                                    listen: false);
                            /// FIX
                           /// addCommentToPost(firestore, widget.cfData.postId!,
                               /// userService.loggedInUser!.username!, myController.text);
                            comments.add(
                                DbComment("YOUR USERNAME", myController.text));
                            myController.text = "";
                            print(userService.loggedInUser!.username!);
                          },
                        )
                      : null,
                ),
              ))),
    ]);
  }
}
