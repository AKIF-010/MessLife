import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'firebase_options.dart';
import 'login_screen.dart';
import 'messlife_logo.dart';
import 'messlife_theme.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Tap app icon -> native splash shows the logo while the app loads.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Loading finished -> hide splash, go straight to the first screen.
  FlutterNativeSplash.remove();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Signed out -> Login.  Already signed in -> Home (so users are not
    // asked to log in on every launch). To ALWAYS open Login, use '/login'.
    final startRoute =
    FirebaseAuth.instance.currentUser == null ? '/login' : '/home';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MessLife',
      theme: messLifeTheme,
      initialRoute: startRoute,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(), // replace with your real home screen
        // TODO: add your other routes used by the login screen:
        // '/signup': (_) => const SignUpScreen(),
        // '/register': (_) => const RegisterScreen(),
        // '/forgot-password': (_) => const ForgotPasswordScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: MessLifeColors.inkDark,
      body: Center(
        child: MessLifeLogo(size: 220, rounded: true),
      ),
    );
  }
}