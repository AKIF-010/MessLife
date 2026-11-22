// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _rememberKey = 'remember_me';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  /// Google accounts are already verified; email/password accounts must verify.
  bool isEmailTrusted(User u) =>
      u.emailVerified || u.providerData.any((p) => p.providerId == 'google.com');

  /// "google" or "email" (matches users/{uid}.auth_provider in the plan).
  String providerOf(User u) =>
      u.providerData.any((p) => p.providerId == 'google.com')
          ? 'google'
          : 'email';

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  // ---- Remember me ----
  // Web: Firebase persistence (LOCAL vs SESSION).
  // Mobile: Firebase always persists, so we store a flag and sign out at the
  // next app start when the user did not tick "Remember me".
  Future<void> _setRemember(bool remember) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberKey, remember);
    } catch (_) {}
    if (kIsWeb) {
      await _auth.setPersistence(
        remember ? Persistence.LOCAL : Persistence.SESSION,
      );
    }
  }

  /// Call once at startup, after Firebase.initializeApp.
  Future<void> applyRememberPolicy() async {
    if (kIsWeb || _auth.currentUser == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_rememberKey) ?? true;
      if (!remember) await signOut();
    } catch (_) {}
  }

  Future<UserCredential> signInWithEmail(
      String email,
      String password, {
        bool remember = true,
      }) async {
    await _setRemember(remember);
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccount(String email, String password) async {
    await _setRemember(true);
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final u = _auth.currentUser;
    if (u == null) return;
    await u.sendEmailVerification();
  }

  /// Refreshes the user from the server. When the email just became verified,
  /// the ID token is refreshed too (so Firestore rules see email_verified).
  Future<User?> reloadUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    await u.reload();
    final fresh = _auth.currentUser;
    if (fresh != null && fresh.emailVerified) {
      await fresh.getIdToken(true);
    }
    return fresh;
  }

  /// Returns null if the user cancelled the Google dialog.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _setRemember(true);
      if (kIsWeb) {
        return await _auth.signInWithPopup(GoogleAuthProvider());
      }
      await _ensureGoogleInit();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(code: 'google-no-token');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw FirebaseAuthException(code: 'google-failed');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _ensureGoogleInit();
      await GoogleSignIn.instance.signOut();
    }
  }
}

/// Maps a Firebase error code to a key in AppStrings.
String authErrorKey(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'invalid-email':
      return 'errInvalidCredential';
    case 'user-not-found':
      return 'errUserNotFound';
    case 'wrong-password':
      return 'errWrongPassword';
    case 'user-disabled':
      return 'errUserDisabled';
    case 'too-many-requests':
      return 'errTooMany';
    case 'network-request-failed':
      return 'errNetwork';
    case 'email-already-in-use':
      return 'errEmailInUse';
    case 'weak-password':
      return 'errWeakPassword';
    case 'google-failed':
    case 'google-no-token':
    case 'account-exists-with-different-credential':
      return 'errGoogle';
    default:
      return 'errGeneric';
  }
}