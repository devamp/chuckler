import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import 'leaderboard_categories.dart';

class Leaderboard extends StatefulWidget {
  const Leaderboard({super.key});

  @override
  State<Leaderboard> createState() => _LeaderboardState();
}

class _LeaderboardState extends State<Leaderboard> {
  String selectedCategory = 'Daily'; // Track the selected category

  // Update the selected category without navigating to a new page
  void selectCategory(String category) {
    setState(() {
      selectedCategory = category; // Update the selected category
    });
  }

  Widget categoryMenu(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          const SizedBox(width: 8),
          buildCategoryButton('Daily'),
          const SizedBox(width: 10),
          buildCategoryButton('Most Posts'),
          const SizedBox(width: 10),
          buildCategoryButton('Longest Streak'),
          const SizedBox(width: 10),
          buildCategoryButton('Hall of Fame'),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  ElevatedButton buildCategoryButton(String category) {
    return ElevatedButton(
      onPressed: () => selectCategory(category), // Handle button press
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedCategory == category ? Colors.white : Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      child: Text(
        category,
        style: TextStyle(
            fontSize: 15,
            color: selectedCategory == category ? Colors.black : Colors.white,
            fontWeight: selectedCategory == category
                ? FontWeight.bold
                : FontWeight.normal),
      ),
    );
  }

  // Content to display based on the selected category
  Widget buildCategoryContent(BuildContext context) {
    switch (selectedCategory) {
      case 'Daily':
        return buildDailyLeaderboard(context);
      case 'Most Posts':
        return buildWeeklyLeaderboard(context);
      case 'Longest Streak':
        return buildMonthlyLeaderboard(context);
      case 'Hall of Fame':
        return buildHallOfFameLeaderboard(context);
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        title: const Text(
          "Local Leaderboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent, // Make the AppBar transparent
        elevation: 0, // Remove shadow for a clean blend with the background
      ),
      extendBodyBehindAppBar: true, // Extend the body behind the AppBar
      body: Container(
        decoration: BoxDecoration(
          gradient: primaryBackgroundGradient(context),
        ),
        child: Column(
          children: [
            const SizedBox(height: 115),
            categoryMenu(context),
            Expanded(
              child: buildCategoryContent(context),
            ),
          ],
        ),
      ),
    );
  }
}
