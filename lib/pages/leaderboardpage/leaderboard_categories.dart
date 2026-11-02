import 'dart:math';
import 'package:chuckler/state/session_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../CustomReusableWidgets/profile_photo.dart';
import '../publicpage/public_page.dart';
import 'top_leaders_banner.dart';

Widget buildDailyLeaderboard(BuildContext context) {
  // Random data for names and positions
  List<String> names = [
    'Devam Patel',
    'Caden Deutscher',
    'John Appleseed',
    'Amy Smith',
    'Kyle Winters',
    'Zarah Missing',
    'Randy',
    'CoolKid99',
    'Harrison Kingston',
    'Zoe Alvarez'
  ];
  List<String> positions = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th'
  ];

  // Random number generator for random selection
  Random random = Random();

  // Generate a list of 10 random leaders
  List<Leader> leaders = List<Leader>.generate(10, (i) {
    return Leader(
      name: names[random.nextInt(names.length)], // Randomly pick a name
      position: positions[i], // Set position based on index
      color: Colors.primaries[random.nextInt(
          Colors.primaries.length)], // Random color from predefined colors
    );
  });

  return Column(
    children: [
      TopLeadersBanner(
        topLeaders: [
          Leader(
              name: 'Devam Patel', position: '1st', color: Colors.amberAccent),
          Leader(name: 'Caden Deutscher', position: '2nd', color: Colors.grey),
          Leader(name: 'John Appleseed', position: '3rd', color: Colors.brown),
        ],
        category: 'Daily',
      ),
      Expanded(child: buildList(leaders, context))
    ],
  );
}

Widget buildWeeklyLeaderboard(BuildContext context) {
  // Random data for names and positions
  List<String> names = [
    'Devam Patel',
    'Caden Deutscher',
    'John Appleseed',
    'Amy Smith',
    'Kyle Winters',
    'Zarah Missing',
    'Randy',
    'CoolKid99',
    'Harrison Kingston',
    'Zoe Alvarez'
  ];
  List<String> positions = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th'
  ];

  // Random number generator for random selection
  Random random = Random();

  // Generate a list of 10 random leaders
  List<Leader> leaders = List<Leader>.generate(10, (i) {
    return Leader(
      name: names[random.nextInt(names.length)], // Randomly pick a name
      position: positions[i], // Set position based on index
      color: Colors.primaries[random.nextInt(
          Colors.primaries.length)], // Random color from predefined colors
    );
  });

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TopLeadersBanner(
        topLeaders: [
          new Leader(
              name: 'Kyle Winters', position: '1st', color: Colors.amberAccent),
          new Leader(name: 'Amy Smith', position: '2nd', color: Colors.grey),
          new Leader(
              name: 'Zarah Missing', position: '3rd', color: Colors.brown)
        ],
        category: 'Most Posts',
      ),
      Expanded(child: buildList(leaders, context))
    ],
  );
}

Widget buildMonthlyLeaderboard(BuildContext context) {
  // Random data for names and positions
  List<String> names = [
    'Devam Patel',
    'Caden Deutscher',
    'John Appleseed',
    'Amy Smith',
    'Kyle Winters',
    'Zarah Missing',
    'Randy',
    'CoolKid99',
    'Harrison Kingston',
    'Zoe Alvarez'
  ];
  List<String> positions = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th'
  ];

  // Random number generator for random selection
  Random random = Random();

  List<Leader> leaders = List<Leader>.generate(10, (i) {
    return Leader(
      name: names[random.nextInt(names.length)], // Randomly pick a name
      position: positions[i], // Set position based on index
      color: Colors.primaries[random.nextInt(
          Colors.primaries.length)], // Random color from predefined colors
    );
  });

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TopLeadersBanner(
        topLeaders: [
          new Leader(
              name: 'Harrison Kingston',
              position: '1st',
              color: Colors.amberAccent),
          new Leader(name: 'Randy', position: '2nd', color: Colors.grey),
          new Leader(name: 'CoolKid99', position: '3rd', color: Colors.brown)
        ],
        category: 'Longest Streak',
      ),
      Expanded(child: buildList(leaders, context))
    ],
  );
}

Widget buildHallOfFameLeaderboard(BuildContext context) {
  // Random data for names and positions
  List<String> names = [
    'Devam Patel',
    'Caden Deutscher',
    'John Appleseed',
    'Amy Smith',
    'Kyle Winters',
    'Zarah Missing',
    'Randy',
    'CoolKid99',
    'Harrison Kingston',
    'Zoe Alvarez'
  ];
  List<String> positions = [
    '1st',
    '2nd',
    '3rd',
    '4th',
    '5th',
    '6th',
    '7th',
    '8th',
    '9th',
    '10th'
  ];

  // Random number generator for random selection
  Random random = Random();

  // Generate a list of 10 random leaders
  List<Leader> leaders = List<Leader>.generate(10, (i) {
    return Leader(
      name: names[random.nextInt(names.length)], // Randomly pick a name
      position: positions[i], // Set position based on index
      color: Colors.primaries[random.nextInt(
          Colors.primaries.length)], // Random color from predefined colors
    );
  });

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TopLeadersBanner(
        topLeaders: [
          new Leader(
              name: 'Violet', position: '1st', color: Colors.amberAccent),
          new Leader(name: 'Joker', position: '2nd', color: Colors.grey),
          new Leader(name: 'Xin Fei', position: '3rd', color: Colors.brown)
        ],
        category: 'Hall of Fame',
      ),
      Expanded(child: buildList(leaders, context))
    ],
  );
}

Widget buildList(List<Leader> entries, BuildContext context) {
  SessionService sessionService = Provider.of<SessionService>(context);

  return ListView.builder(
    padding: const EdgeInsets.all(10),
    scrollDirection: Axis.vertical,
    itemCount: entries.length - 2,
    itemBuilder: (BuildContext context, int index) {
      int rank = index + 4;

      if (index == entries.length - 3) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: GestureDetector(
            onTap: () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PublicPage(
                      username: sessionService.loggedInUser?.username ??
                          'Undefined User'),
                ),
              )
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.amberAccent[200]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 15,
                  ),
                  ProfilePhoto(
                    username:
                        sessionService.loggedInUser?.username ?? 'Undefined User',
                    img: '',
                    radius: 22.0,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      sessionService.loggedInUser?.username ?? 'Undefined User',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 100),
                  Text(
                    '483',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: GestureDetector(
            onTap: () => {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PublicPage(username: entries[index].name),
                ),
              )
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Colors.black54),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 15,
                  ),
                  ProfilePhoto(
                    username: entries[index].name,
                    img: '',
                    radius: 22.0,
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  SizedBox(
                    width: 150,
                    child: Text(
                      entries[index].name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 100),
                  Text(
                    rank.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    },
  );
}
