import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:chuckler/route_generator.dart';
import 'package:provider/provider.dart';
import './firebase/firebase_options.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'state/create_service.dart';
import 'state/friends_service.dart';
import 'state/account_service.dart';
import 'state/feed_service.dart';
import 'state/prompt_service.dart';
import 'state/session_service.dart';
import 'state/voting_service.dart';
import 'database/isarDB.dart';
import 'Theme/theme.dart';

/// Set at launch with --dart-define=USE_EMULATOR=true (off by default).
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

/// Where the emulators run. localhost works for the iOS simulator.
const String emulatorHost =
    String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');

Future<void> main() async {
  DefaultFirebaseOptions fb = DefaultFirebaseOptions();
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.openDB();

  try {
    await fb.initializeFirebase();

    // Local Firebase emulators are opt-in at launch, never edited in or out:
    //   flutter run --dart-define=USE_EMULATOR=true
    // On a physical iPhone, also pass your Mac's LAN IP:
    //   --dart-define=EMULATOR_HOST=192.168.1.x
    // Builds without the flag (including release) use production Firebase.
    if (useEmulator) {
      // No offline cache against the emulators: their data is reset often,
      // and a cached copy from an earlier run (served while the app is still
      // reconnecting) shows stale counts. Production keeps the cache.
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: false);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
      FirebaseFunctions.instance.useFunctionsEmulator(emulatorHost, 5001);
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      debugPrint('Chuckler: using Firebase emulators at $emulatorHost');
    }




    runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SessionService()),
        ChangeNotifierProvider(create: (context) => PromptService()),
        ChangeNotifierProvider(create: (context) => FeedService()),
        ChangeNotifierProvider(create: (context) => VotingService()),
        ChangeNotifierProvider(create: (context) => CreateService()),
        ChangeNotifierProvider(create: (context) => FriendsService()),
        ChangeNotifierProvider(create: (context) => AccountService()),
        Provider<IsarService>(create: (context) => IsarService()),
        Provider<FirebaseFirestore>(create: (context) => FirebaseFirestore.instance)
      ],
      child: const MyApp(),
    ));
  } catch (e) {
    debugPrint("Error initiating Firebase: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chuckler',
      debugShowCheckedModeBanner: false,
      theme: darkThemeData(context),
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
