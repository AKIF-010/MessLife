import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:messlife/core/app_colors.dart';
import 'package:messlife/core/language_controller.dart';
import 'package:messlife/firebase_options.dart';
import 'package:messlife/screens/home_screen.dart';
import 'package:messlife/screens/login_screen.dart';
import 'package:messlife/splash/messlife_splash.dart'; // <- fix folder

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MessLifeApp());
}

class MessLifeApp extends StatefulWidget {
  const MessLifeApp({super.key});

  @override
  State<MessLifeApp> createState() => _MessLifeAppState();
}

class _MessLifeAppState extends State<MessLifeApp> {
  final LanguageController _language = LanguageController();

  /// Real loading progress (0..1). The splash loader bar follows this value.
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  late final Future<void> _ready;

  /// Result of the startup auth check. Used to choose the first screen.
  User? _user;

  @override
  void initState() {
    super.initState();
    // Start a little after the first frames so the heavy startup work does not
    // jank the beginning of the splash animation.
    _ready = Future<void>.delayed(
      const Duration(milliseconds: 800),
    ).then((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      _progress.value = 0.1;

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _progress.value = 0.5;

      // Restore the saved login session (first auth state event).
      _user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 6));
      _progress.value = 0.9;
    } catch (e) {
      // Never hang on the splash; the splash still finishes.
      debugPrint('Bootstrap failed: $e');
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      controller: _language,
      child: MaterialApp(
        title: 'MessLife',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
        ),
        // Splash first. After it finishes:
        // Already signed in -> Home. Otherwise -> Login.
        home: Builder(
          builder: (context) => MessLifeSplash(
            waitFor: _ready,
            progress: _progress,
            onFinished: () => Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 250),
                pageBuilder: (_, _, _) =>
                _user != null ? const HomeScreen() : const LoginScreen(),
                transitionsBuilder: (_, a, _, child) =>
                    FadeTransition(opacity: a, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}