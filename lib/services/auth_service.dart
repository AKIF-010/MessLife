import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccount(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Returns null if the user cancelled the Google dialog.
  Future<UserCredential?> signInWithGoogle() async {
    try {
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