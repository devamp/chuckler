import 'package:chuckler/CustomReusableWidgets/profile_photo.dart';
import 'package:chuckler/state/prompt_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/models.dart';

class CreatePageLoadingBar extends StatefulWidget {
  final int pVal;
  final DbUser? friend;
  const CreatePageLoadingBar({super.key, required this.pVal, required this.friend});

  @override
  _CreatePageLoadingBarState createState() => _CreatePageLoadingBarState();
}

class _CreatePageLoadingBarState extends State<CreatePageLoadingBar>
    with TickerProviderStateMixin {
  String timeRemaining = "";
  int timeLeft = 0;

  //Set the progress indicator
  void _updateProgress() {
    // Get current UTC time
    final now = DateTime.now().toUtc();

    // Calculate time remaining in the day (in seconds)
    final midnightUtc = DateTime.utc(now.year, now.month, now.day, 0, 0);
    final secondsRemaining = -midnightUtc.difference(now).inSeconds.toDouble();

    // Calculate progress value (percentage)
    const totalSecondsInDay = 24 * 60 * 60;
    final hoursRemaining =
        ((totalSecondsInDay - secondsRemaining) / (60 * 60)).round();

    // Update state and potentially rebuild the widget
    setState(() {
      timeLeft = hoursRemaining;
      timeRemaining = hoursRemaining.toString();
    });
  }

  @override
  void initState() {
    super.initState();
    _updateProgress();
  }

  @override
  Widget build(BuildContext context) {
    PromptService promptService = Provider.of<PromptService>(context, listen: false);
    double screenHeight = MediaQuery.of(context).size.height;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
          flex: 5,
          child: Text(
            timeRemaining + (timeLeft > 1 ? " hours left" : " hour left"),
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'OpenSans',
                fontSize: screenHeight / 70,
                fontWeight: FontWeight.w700),
          )),
      Expanded(flex: 3, child: Container()),
      Expanded(
          flex: 8,
          child: Container(
              alignment: Alignment.centerRight,
              decoration: const BoxDecoration(),
              height: 30,
              //TODO add friend image
              child: Row(children: [
                widget.friend != null ? ProfilePhoto(username: "Text", img: "", radius: 15): Container(),
                Text(" ${widget.friend == null ? "         " : " + "} ${promptService.prompts![widget.pVal].responses} Answered",
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontSize: screenHeight / 70))
              ]))),
      /*RichText(
            textAlign: TextAlign.center,
              maxLines: 1,
              text: TextSpan(
                  children: [
            WidgetSpan(
                child: ),
            TextSpan(
                text: "+ 100 answered this",
                style: Theme.of(context).textTheme.bodySmall)
          ]))*/
    ]);
  }
}
