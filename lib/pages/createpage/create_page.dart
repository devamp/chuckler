import 'dart:async';
import 'package:chuckler/PageTransitioner.dart';
import 'package:chuckler/pages/loginpage/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Theme/theme.dart';
import '../../data/friend_prompts.dart';
import '../../data/posts.dart';
import '../../data/prompt_stats.dart';
import '../../data/prompts.dart';
import '../../data/users.dart';
import '../../database/isarDB.dart';
import '../../database/models.dart';
import '../../state/create_service.dart';
import '../../state/prompt_service.dart';
import '../../state/session_service.dart';
import 'create_answer_box.dart';
import 'create_prompt_card.dart';
import 'create_prompt_sheet.dart';
import 'create_stats.dart';
import 'create_streak_sheet.dart';

/// Today's prompts, one per page. Swipe left and right between them, answer
/// the one showing, and see how each prompt and your answer are doing.
class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  late final PageController _pages;
  final TextEditingController _answer = TextEditingController();
  final FocusNode _answerFocus = FocusNode();
  bool _posting = false;
  DateTime _now = DateTime.now().toUtc();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    CreateService createService =
        Provider.of<CreateService>(context, listen: false);
    _pages = PageController(initialPage: createService.page);
    // after the first frame, since loading notifies listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      loadPrompts(createService);
      if (createService.length > 0) {
        _answer.text = createService.draftFor(createService.page);
      }
    });
    // keeps the time-left labels current
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() {
        _now = DateTime.now().toUtc();
      });
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _pages.dispose();
    _answer.dispose();
    _answerFocus.dispose();
    super.dispose();
  }

  void loadPrompts(CreateService createService) {
    PromptService promptService =
        Provider.of<PromptService>(context, listen: false);
    DbUser? user =
        Provider.of<SessionService>(context, listen: false).loggedInUser;
    List<DbPrompt> live = promptService.prompts ?? [];
    // with no real prompt live, debug builds show sample prompts so the page
    // can be seen working
    bool includeSamples = kDebugMode && live.every(isAwaitingPrompt);
    createService.setPrompts(live, promptService.userPostsForPrompts,
        includeSamples: includeSamples,
        uid: user?.uid ?? '',
        username: user?.username ?? '');
    createService.loadStats(
        Provider.of<FirebaseFirestore>(context, listen: false),
        user?.uid ?? '');
  }

  void onPageChanged(int i) {
    CreateService createService =
        Provider.of<CreateService>(context, listen: false);
    createService.setPage(i);
    _answer.text = createService.draftFor(i);
  }

  Future<void> post() async {
    CreateService createService =
        Provider.of<CreateService>(context, listen: false);
    int i = createService.page;
    DbPrompt prompt = createService.prompts[i];
    String text = _answer.text.trim();
    if (_posting ||
        text.isEmpty ||
        isAwaitingPrompt(prompt) ||
        createService.answered(i)) {
      return;
    }
    DbUser? user =
        Provider.of<SessionService>(context, listen: false).loggedInUser;
    if (user == null) {
      showNotLoggedIn();
      return;
    }
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    _answerFocus.unfocus();
    setState(() {
      _posting = true;
    });

    try {
      DbPost posted;
      if (isLocalPrompt(prompt)) {
        // answers to sample prompts and phone-only friend prompts stay here
        posted = DbPost('sample-${prompt.promptId}', text, user.username,
            user.uid, 0, 0, 0, prompt.promptId, prompt.promptDateId)
          ..mine = true;
      } else {
        posted = await createPost(firestore, user, prompt, text);
        if (!mounted) return;
        Provider.of<PromptService>(context, listen: false).setPostForPrompt(
            prompt.promptDateId!, prompt.promptId!, posted);
        await cachePost(firestore, user, posted);
      }
      createService.markPosted(i, posted);
      _answer.clear();
      await createService.loadStats(firestore, user.uid ?? '', only: i);
    } catch (e) {
      debugPrint("$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Couldn't post your answer. Try again.")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _posting = false;
        });
      }
    }
  }

  /// Caches the new post on the phone and bumps the user's post count. The
  /// post already exists, so failures here are only logged.
  Future<void> cachePost(
      FirebaseFirestore firestore, DbUser user, DbPost posted) async {
    try {
      await Provider.of<IsarService>(context, listen: false)
          .addOnePostToDB(posted);
    } catch (e) {
      debugPrint("$e");
    }
    try {
      await incrementNumPosts(firestore, user.uid!);
    } catch (e) {
      debugPrint("$e");
    }
  }

  void like(CreateService createService, int i) {
    bool liked = createService.toggleLike(i);
    DbPrompt prompt = createService.prompts[i];
    if (isLocalPrompt(prompt)) return;
    likePrompt(
        Provider.of<FirebaseFirestore>(context, listen: false),
        Provider.of<SessionService>(context, listen: false).loggedInUser?.uid ??
            '',
        prompt,
        liked);
  }

  Future<void> createPrompt(CreateService createService) async {
    DateTime now = DateTime.now().toUtc();
    if (!createService.canCreatePrompt(now)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("You've made today's prompt. Come back tomorrow!")));
      return;
    }
    DbUser? user =
        Provider.of<SessionService>(context, listen: false).loggedInUser;
    if (user == null) {
      showNotLoggedIn();
      return;
    }
    FirebaseFirestore firestore =
        Provider.of<FirebaseFirestore>(context, listen: false);
    final parts = await showPromptBuilder(context);
    if (parts == null || !mounted) return;
    _answerFocus.unfocus();
    DbPrompt prompt =
        await createFriendPrompt(firestore, user, parts.$1, parts.$2);
    int page = createService.addCreatedPrompt(
        prompt,
        PromptCreator(
            uid: user.uid ?? '',
            username: user.username ?? '',
            photoUrl: user.profilePicture),
        now);
    _answer.clear();
    // after the PageView has rebuilt with the new page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pages.hasClients) _pages.jumpToPage(page);
    });
    await createService.loadStats(firestore, user.uid ?? '', only: page);
  }

  void showNotLoggedIn() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Not Logged In'),
              content: const Text('You cannot post unless you are logged in.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Go to Login'),
                  onPressed: () {
                    Navigator.push(
                        context, SmoothPageTransition(child: LoginPage()));
                  },
                )
              ]);
        });
  }

  @override
  Widget build(BuildContext context) {
    CreateService createService =
        Provider.of<CreateService>(context, listen: true);
    bool typing = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Container(
      decoration: BoxDecoration(gradient: primaryBackgroundGradient(context)),
      child: SafeArea(
        bottom: false,
        child: createService.length == 0
            ? const Center(
                child: CircularProgressIndicator(color: Colors.amber))
            : Column(
                children: [
                  if (!typing) header(createService),
                  Expanded(
                    child: NotificationListener<ScrollStartNotification>(
                      // a swipe between prompts puts the keyboard away
                      onNotification: (n) {
                        if (n.dragDetails != null) _answerFocus.unfocus();
                        return false;
                      },
                      child: PageView.builder(
                        controller: _pages,
                        itemCount: createService.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, i) => PromptCard(
                          prompt: createService.prompts[i],
                          creator: createService.creatorFor(i),
                          mine: createService.creatorFor(i).uid ==
                              Provider.of<SessionService>(context,
                                      listen: false)
                                  .loggedInUser
                                  ?.uid,
                          answer: createService.postFor(i)?.answer ??
                              createService.draftFor(i),
                          answered: createService.answered(i),
                          stats: createService.statsFor(i),
                          now: _now,
                          likes: createService.likesFor(i),
                          liked: createService.likedFor(i),
                          onLike: () => like(createService, i),
                          compact: typing,
                        ),
                      ),
                    ),
                  ),
                  PageDots(
                    count: createService.length,
                    current: createService.page,
                    answered: [
                      for (int i = 0; i < createService.length; i++)
                        createService.answered(i)
                    ],
                  ),
                  bottomArea(createService),
                ],
              ),
      ),
    );
  }

  /// Title centered, with the streak on the left and the + on the right
  Widget header(CreateService createService) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: createService.streak > 0
                  ? StreakChip(
                      days: createService.streak,
                      onTap: () =>
                          showStreakSheet(context, createService.streak))
                  : const SizedBox(),
            ),
          ),
          Flexible(
            flex: 3,
            child: Column(
              children: [
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text("TODAY'S PROMPTS",
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'NewAmsterdam',
                          fontSize: 30)),
                ),
                Text(
                  '${createService.answeredCount} of '
                  '${createService.answerableCount} answered',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70, fontFamily: 'OpenSans'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: CreatePromptButton(
                enabled: createService.canCreatePrompt(_now),
                onTap: () => createPrompt(createService),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomArea(CreateService createService) {
    int i = createService.page;
    DbPrompt prompt = createService.prompts[i];
    if (isAwaitingPrompt(prompt)) {
      return const BottomNote(
          icon: Icons.hourglass_top,
          text: "Answers open when today's prompt drops");
    }
    if (createService.answered(i)) {
      return YourAnswerPanel(
          stats: createService.statsFor(i)?.mine,
          answers: createService.statsFor(i)?.answers ?? 0);
    }
    return AnswerBox(
      controller: _answer,
      focusNode: _answerFocus,
      posting: _posting,
      onChanged: (text) => createService.setDraft(i, text),
      onPost: post,
    );
  }
}
