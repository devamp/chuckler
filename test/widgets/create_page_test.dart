// Widget tests for the Create tab: swiping between prompts, answering, and
// the stats. With no live prompt, debug builds (and tests) add sample prompts.

import 'package:chuckler/data/prompts.dart';
import 'package:chuckler/database/models.dart';
import 'package:chuckler/pages/createpage/create_page.dart';
import 'package:chuckler/pages/createpage/create_prompt_card.dart';
import 'package:chuckler/state/create_service.dart';
import 'package:chuckler/state/prompt_service.dart';
import 'package:chuckler/state/session_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'fonts.dart';

DbPrompt livePrompt(String id, String before, int responses) {
  return DbPrompt(before, '', 'day-1', id, '2026-11-02', 'global')
    ..responses = responses;
}

void main() {
  late CreateService create;
  late PromptService promptService;
  late FakeFirebaseFirestore firestore;

  Future<void> pumpCreatePage(WidgetTester tester,
      {List<DbPrompt>? live,
      bool loggedIn = true,
      Size size = const Size(393, 852)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    firestore = FakeFirebaseFirestore();
    create = CreateService();
    promptService = PromptService();
    for (final p in live ?? [awaitingPrompt()]) {
      promptService.addPrompt(p);
      promptService.addPostForPrompt(null);
    }
    final session = SessionService();
    if (loggedIn) session.setLoggedInUser(DbUser('me', 'caden', 0, 0, ''));
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: promptService),
        ChangeNotifierProvider.value(value: create),
        Provider<FirebaseFirestore>.value(value: firestore),
      ],
      child: const MaterialApp(home: Scaffold(body: CreatePage())),
    ));
    await tester.pumpAndSettle();
  }

  // text inside the prompt card, not the answer box
  Finder promptText(String text) => find.descendant(
      of: find.byType(PromptCard),
      matching: find.textContaining(text, findRichText: true));

  Finder onCard(String text) => find.descendant(
      of: find.byType(PromptCard), matching: find.text(text));

  Future<void> swipeLeft(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
  }

  Future<void> swipeRight(WidgetTester tester) async {
    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();
  }

  bool postEnabled(WidgetTester tester) => tester
      .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Post'))
      .enabled;

  group('with no live prompt', () {
    testWidgets('opens on the awaiting prompt, with sample prompts after it',
        (tester) async {
      await pumpCreatePage(tester);

      expect(promptText('in the oven'), findsOneWidget);
      expect(find.text("Answers open when today's prompt drops"),
          findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('1 of 3 answered'), findsOneWidget);
      expect(find.byTooltip('4 day streak'), findsOneWidget);
      expect(create.length, 4);
    });

    testWidgets('swiping left shows the next prompt with its segment and stats',
        (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);

      expect(promptText('first date'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Sample'), findsOneWidget);
      expect(find.text('answers'), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
      expect(postEnabled(tester), isFalse);

      await swipeRight(tester);
      expect(promptText('in the oven'), findsOneWidget);
    });

    testWidgets('typing fills the blank, and posting shows your answer panel',
        (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);

      await tester.enterText(find.byType(TextField), 'I still live with my mom');
      await tester.pump();
      expect(promptText('I still live with my mom'), findsOneWidget);
      expect(postEnabled(tester), isTrue);

      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(find.text('YOUR ANSWER'), findsOneWidget);
      expect(find.text('Waiting for its first matchup. Check back soon!'),
          findsOneWidget);
      expect(find.text('Answered'), findsOneWidget);
      expect(find.text('2 of 3 answered'), findsOneWidget);
      expect(promptText('I still live with my mom'), findsOneWidget);
      // sample answers never reach Firestore
      expect((await firestore.collection('Posts').get()).docs, isEmpty);
    });

    testWidgets('an answer that has been out a while shows its stats',
        (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);
      await swipeLeft(tester);

      expect(promptText('Rocky Road Rage'), findsOneWidget);
      expect(find.text('#12 of 340'), findsOneWidget);
      expect(find.text('Top 4%'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
      // 23 wins of 36 votes
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('Wins per hour, last 6 hours'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('drafts are kept when swiping away and back', (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);
      await tester.enterText(find.byType(TextField), 'Half a draft');
      await tester.pump();

      await swipeLeft(tester);
      await swipeLeft(tester);
      expect(promptText('bus is late'), findsOneWidget);
      expect(find.text('Half a draft'), findsNothing);

      await swipeRight(tester);
      await swipeRight(tester);
      expect(find.text('Half a draft'), findsOneWidget);
      expect(promptText('Half a draft'), findsOneWidget);
    });
  });

  group('stats interactions', () {
    testWidgets('tapping the heart likes the prompt, and again unlikes it',
        (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);
      final before = create.likesFor(1);
      expect(onCard('$before'), findsOneWidget);

      await tester.tap(find.byTooltip('Like this prompt'));
      await tester.pump();
      expect(onCard('${before + 1}'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.byTooltip('Unlike this prompt'));
      await tester.pump();
      expect(onCard('$before'), findsOneWidget);
    });

    testWidgets('tapping the friends opens everyone who answered',
        (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);
      expect(find.text('6 friends'), findsOneWidget);

      await tester.tap(find.text('6 friends'));
      await tester.pumpAndSettle();

      expect(find.text('6 FRIENDS ANSWERED'), findsOneWidget);
      for (final name in ['skyler', 'marco', 'ava', 'jules', 'priya', 'theo']) {
        expect(
            find.descendant(
                of: find.byType(BottomSheet), matching: find.text(name)),
            findsOneWidget);
      }
    });

    testWidgets('no friends answered means nothing to open', (tester) async {
      await pumpCreatePage(tester);
      for (var i = 0; i < 3; i++) {
        await swipeLeft(tester);
      }
      await tester.tap(find.text('No friends yet'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ANSWERED'), findsNothing);
    });

    testWidgets('tapping the streak opens the calendar and top friend streaks',
        (tester) async {
      await pumpCreatePage(tester);
      await tester.tap(find.byTooltip('4 day streak'));
      await tester.pumpAndSettle();

      expect(find.text('4 DAY STREAK'), findsOneWidget);
      // today is answered in the sample history; four days ago was missed
      final now = DateTime.now().toUtc();
      expect(find.bySemanticsLabel(RegExp(' ${now.day}, answered\$')),
          findsOneWidget);
      final gap = now.subtract(const Duration(days: 4));
      if (gap.month == now.month) {
        expect(find.bySemanticsLabel(RegExp(' ${gap.day}, missed\$')),
            findsOneWidget);
      }

      await tester.scrollUntilVisible(find.text('jules'), 100,
          scrollable: find.byType(Scrollable).last);
      expect(find.text('TOP FRIEND STREAKS'), findsOneWidget);
      expect(find.text("You're #4 of 7 with your friends"), findsOneWidget);
      // the top 5 friends, not the user and not the 6th friend
      for (final name in ['ava', 'theo', 'marco', 'skyler', 'jules']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('priya'), findsNothing);
      expect(find.text('caden'), findsNothing);
    });

    testWidgets('the calendar goes back a month but not past this one',
        (tester) async {
      await pumpCreatePage(tester);
      await tester.tap(find.byTooltip('4 day streak'));
      await tester.pumpAndSettle();

      final next = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.chevron_right));
      expect(next.onPressed, isNull);

      final title = find.textContaining(RegExp(r'^[A-Z][a-z]+ \d{4}$'));
      final shownBefore = tester.widget<Text>(title).data;
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(title).data, isNot(shownBefore));
    });
  });

  group('with live prompts', () {
    final live = [
      livePrompt('p1', 'My toaster would say ', 57),
      livePrompt('p2', 'The worst superpower is ', 12),
    ];

    testWidgets('shows only the live prompts and their answer counts',
        (tester) async {
      await pumpCreatePage(tester, live: live);

      expect(create.length, 2);
      expect(find.text('Sample'), findsNothing);
      expect(find.text('57'), findsOneWidget);
      expect(find.text('0 of 2 answered'), findsOneWidget);
    });

    testWidgets('posting writes a Posts doc and records it for the prompt',
        (tester) async {
      // there is no IsarService here, so caching the post on the phone logs
      // a ProviderNotFound error and the post still goes through
      await pumpCreatePage(tester, live: live);
      await firestore.collection('Users').doc('me').set({'posts': 2});
      await tester.enterText(find.byType(TextField), 'Not again');
      await tester.pump();
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      final posts = (await firestore.collection('Posts').get()).docs;
      expect(posts, hasLength(1));
      expect(posts.first['answer'], 'Not again');
      expect(posts.first['promptId'], 'p1');
      expect(posts.first['promptDateId'], 'day-1');
      expect(promptService.userPostsForPrompts[0]?.answer, 'Not again');
      final me = await firestore.collection('Users').doc('me').get();
      expect(me['posts'], 3);
      expect(find.text('YOUR ANSWER'), findsOneWidget);
      expect(find.text('1 of 2 answered'), findsOneWidget);
    });

    testWidgets('swiping puts the keyboard away', (tester) async {
      await pumpCreatePage(tester, live: live);
      await tester.showKeyboard(find.byType(TextField));
      expect(tester.testTextInput.isVisible, isTrue);

      await swipeLeft(tester);

      expect(promptText('worst superpower'), findsOneWidget);
      expect(tester.testTextInput.isVisible, isFalse);
    });

    testWidgets('posting while logged out asks you to log in', (tester) async {
      await pumpCreatePage(tester, live: live, loggedIn: false);
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();

      expect(find.text('Not Logged In'), findsOneWidget);
      expect((await firestore.collection('Posts').get()).docs, isEmpty);
    });
  });

  for (final size in const [Size(393, 852), Size(375, 667)]) {
    testWidgets('fits without overflow at $size', (tester) async {
      await loadRealFonts();
      await pumpCreatePage(tester, size: size);
      expect(tester.takeException(), isNull);

      // unanswered, then answered with stats
      await swipeLeft(tester);
      expect(tester.takeException(), isNull);
      await swipeLeft(tester);
      expect(find.text('YOUR ANSWER'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('4 day streak'));
      await tester.pumpAndSettle();
      expect(find.text('4 DAY STREAK'), findsOneWidget);
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Create a prompt for your friends'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first,
          'The most suspicious thing to find in a fridge is');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  group('prompt creators', () {
    testWidgets('daily prompts come from Chuckler, with a fun bio',
        (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);
      await swipeLeft(tester);
      expect(find.text('Chuckler'), findsOneWidget);

      await tester.tap(find.text('Chuckler'));
      await tester.pumpAndSettle();
      expect(find.text('Official account'), findsOneWidget);
      expect(find.textContaining('Professional blank-filler'), findsOneWidget);
    });

    testWidgets('a friend prompt shows the friend who wrote it',
        (tester) async {
      await pumpCreatePage(tester);
      await swipeLeft(tester);
      expect(find.text('ava'), findsOneWidget);

      await tester.tap(find.text('ava'));
      await tester.pumpAndSettle();
      expect(find.text('Friend'), findsOneWidget);
      expect(find.text('Their full profile will open here.'), findsOneWidget);
    });

    testWidgets('live daily prompts come from Chuckler', (tester) async {
      await pumpCreatePage(tester,
          live: [livePrompt('p1', 'My toaster would say ', 57)]);
      expect(find.text('Chuckler'), findsOneWidget);
    });
  });

  group('creating a prompt', () {
    Future<void> openBuilder(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Create a prompt for your friends'));
      await tester.pumpAndSettle();
    }

    Finder builderField(int i) => find.descendant(
        of: find.byType(BottomSheet), matching: find.byType(TextField)).at(i);

    bool sendEnabled(WidgetTester tester) => tester
        .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Send to friends'))
        .enabled;

    testWidgets('the builder previews the prompt as you type', (tester) async {
      await pumpCreatePage(tester);
      await openBuilder(tester);

      expect(find.text('NEW PROMPT'), findsOneWidget);
      expect(sendEnabled(tester), isFalse);

      await tester.enterText(builderField(0), '  My dog thinks  ');
      await tester.enterText(builderField(1), 'is a snack');
      await tester.pump();

      expect(
          find.descendant(
              of: find.byType(BottomSheet),
              matching: find.textContaining('My dog thinks ________ is a snack',
                  findRichText: true)),
          findsOneWidget);
      expect(sendEnabled(tester), isTrue);
    });

    testWidgets('sending adds the prompt as your own, on this phone only',
        (tester) async {
      await pumpCreatePage(tester);
      await openBuilder(tester);
      await tester.enterText(builderField(0), 'My dog thinks');
      await tester.enterText(builderField(1), 'is a snack');
      await tester.pump();
      await tester.tap(find.text('Send to friends'));
      await tester.pumpAndSettle();

      expect(create.length, 5);
      expect(create.page, 4);
      expect(promptText('My dog thinks'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Not shared yet'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('1 of 4 answered'), findsOneWidget);
      expect(find.text('No friends yet'), findsOneWidget);

      // answering your own prompt stays local too
      await tester.enterText(find.byType(TextField), 'a vacuum cleaner');
      await tester.pump();
      await tester.tap(find.text('Post'));
      await tester.pumpAndSettle();
      expect(find.text('YOUR ANSWER'), findsOneWidget);
      expect((await firestore.collection('Posts').get()).docs, isEmpty);
    });

    testWidgets('only one new prompt a day', (tester) async {
      await pumpCreatePage(tester);
      await openBuilder(tester);
      await tester.enterText(builderField(0), 'First prompt');
      await tester.pump();
      await tester.tap(find.text('Send to friends'));
      await tester.pumpAndSettle();

      await openBuilder(tester);
      expect(find.text('NEW PROMPT'), findsNothing);
      expect(find.text("You've made today's prompt. Come back tomorrow!"),
          findsOneWidget);
    });

    testWidgets('backing out of the builder adds nothing', (tester) async {
      await pumpCreatePage(tester);
      await openBuilder(tester);
      await tester.enterText(builderField(0), 'Never mind');
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();

      expect(create.length, 4);
      expect(create.canCreatePrompt(DateTime.now().toUtc()), isTrue);
    });
  });
}
