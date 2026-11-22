// File: lib/services/auth_flow.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/language_controller.dart';
import '../screens/guest_dashboard_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/verify_email_screen.dart';
import '../widgets/common_widgets.dart';
import 'auth_service.dart';
import 'user_service.dart';

enum AuthStep { verifyEmail, registration, ready }

/// Central place for "login only when needed".
///
/// Gate any protected action:
///   final ok = await AuthFlow.ensureReady(context, reasonKey: 'reasonChat');
///   if (ok && context.mounted) { ...do the action... }
///
/// If the user is not signed in, it opens Login -> (Verify email) ->
/// (Registration) and then returns to the screen that asked.
class AuthFlow {
  AuthFlow._();

  /// Pass to MaterialApp.navigatorKey.
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  static Route<dynamic>? _anchor; // the screen that asked for login
  static Completer<bool>? _completer;
  static String? _reasonKey;

  /// Why login is needed (shown as a banner on the Login screen).
  static String? get reasonKey => _reasonKey;

  /// What the signed-in user still has to do.
  static Future<AuthStep> resolveStep(User user, {required String locale}) async {
    if (!AuthService.instance.isEmailTrusted(user)) {
      return AuthStep.verifyEmail;
    }
    final data = await UserService.instance.ensureProfile(
      user,
      provider: AuthService.instance.providerOf(user),
      locale: locale,
    );
    return data['onboarding_complete'] == true
        ? AuthStep.ready
        : AuthStep.registration;
  }

  static Future<bool> ensureReady(
      BuildContext context, {
        String? reasonKey,
      }) async {
    abort(); // drop any stale pending flow
    final locale = LanguageScope.of(context).code;
    final user = AuthService.instance.currentUser;

    if (user != null) {
      try {
        final step = await resolveStep(user, locale: locale);
        if (step == AuthStep.ready) return true;
      } catch (_) {
        if (context.mounted) {
          showAppSnack(context, context.tr('errNetwork'));
        }
        return false;
      }
    }

    if (!context.mounted) return false;
    _anchor = ModalRoute.of(context);
    _reasonKey = reasonKey;
    final completer = _completer = Completer<bool>();

    if (user == null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      await advance();
    }
    return completer.future;
  }

  /// Call after login / sign-up / verification / registration succeeds.
  /// Decides the next screen, or finishes the flow.
  static Future<void> advance() async {
    final nav = navKey.currentState;
    final ctx = navKey.currentContext;
    final user = AuthService.instance.currentUser;
    if (nav == null || ctx == null || user == null) return;

    final locale = LanguageScope.of(ctx).code;
    final AuthStep step;
    try {
      step = await resolveStep(user, locale: locale);
    } catch (_) {
      if (ctx.mounted) showAppSnack(ctx, ctx.tr('errNetwork'));
      return;
    }

    switch (step) {
      case AuthStep.verifyEmail:
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
        );
      case AuthStep.registration:
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const RegistrationScreen()),
        );
      case AuthStep.ready:
        _finish(nav);
    }
  }

  static void _finish(NavigatorState nav) {
    final anchor = _anchor;
    final completer = _completer;
    _anchor = null;
    _completer = null;
    _reasonKey = null;

    if (anchor != null) {
      // Gated action: go back to the screen that asked for login.
      nav.popUntil((r) => r == anchor || r.isFirst);
      completer?.complete(true);
    } else {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
      );
    }
  }

  /// User backed out of the login screen.
  static void abort() {
    _anchor = null;
    _reasonKey = null;
    final c = _completer;
    _completer = null;
    if (c != null && !c.isCompleted) c.complete(false);
  }

  /// User left the verify/registration step without finishing.
  static void cancel() {
    final nav = navKey.currentState;
    if (nav == null) return;
    final anchor = _anchor;
    final completer = _completer;
    _anchor = null;
    _completer = null;
    _reasonKey = null;

    if (anchor != null) {
      nav.popUntil((r) => r == anchor || r.isFirst);
      if (completer != null && !completer.isCompleted) completer.complete(false);
    } else {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GuestDashboardScreen()),
            (_) => false,
      );
    }
  }
}