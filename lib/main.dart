// File: lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:messlife/core/app_colors.dart';
import 'package:messlife/core/language_controller.dart';
import 'package:messlife/firebase_options.dart';
import 'package:messlife/screens/guest_dashboard_screen.dart';
import 'package:messlife/screens/home_screen.dart';
import 'package:messlife/screens/registration_screen.dart';
import 'package:messlife/screens/verify_email_screen.dart';
import 'package:messlife/services/auth_flow.dart';
import 'package:messlife/services/auth_service.dart';
import 'package:messlife/splash/messlife_splash.dart';

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

  /// Result of the startup auth check.
  User? _user;

  /// What a signed-in user still has to do (verify email / registration).
  AuthStep? _step;

  /// True when we could not read the profile (offline, rules...).
  bool _stepFailed = false;

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
      _progress.value = 0.4;

      // "Remember me" off -> sign out at app start (mobile).
      await AuthService.instance.applyRememberPolicy();

      // Restore the saved login session (first auth state event).
      _user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 6));
      _progress.value = 0.7;

      // Signed in: find out whether verification / registration is pending.
      final u = _user;
      if (u != null) {
        try {
          _step = await AuthFlow.resolveStep(u, locale: _language.code);
        } catch (e) {
          _stepFailed = true;
          debugPrint('Profile check failed: $e');
        }
      }
      _progress.value = 0.9;
    } catch (e) {
      // Never hang on the splash; the splash still finishes.
      debugPrint('Bootstrap failed: $e');
    }
  }

  /// First screen after the splash.
  /// Not signed in            -> Guest Dashboard (no login needed)
  /// Signed in, not verified  -> Verify Email
  /// Signed in, no profile    -> Registration
  /// Signed in and complete   -> Home
  Widget _firstScreen() {
    if (_user == null) return const GuestDashboardScreen();
    if (_stepFailed) return const HomeScreen();
    switch (_step) {
      case AuthStep.verifyEmail:
        return const VerifyEmailScreen();
      case AuthStep.registration:
        return const RegistrationScreen();
      case AuthStep.ready:
      case null:
        return const HomeScreen();
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
        navigatorKey: AuthFlow.navKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'PlusJakartaSans',
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
        ),
        home: Builder(
          builder: (context) => MessLifeSplash(
            waitFor: _ready,
            progress: _progress,
            onFinished: () => Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 250),
                pageBuilder: (_, _, _) => _firstScreen(),
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