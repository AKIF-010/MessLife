// lib/login_screen.dart
//
// Email/password + Google + Facebook + Sign Up link.
// No phone login, no Lottie, no fade animation.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'messlife_logo.dart';
import 'messlife_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _emailLoading = false;
  bool _googleLoading = false;
  bool _facebookLoading = false;

  bool get _busy => _emailLoading || _googleLoading || _facebookLoading;

  static const _border = Color(0xFFDDE1F5);
  static const _hint = Color(0xFFAAAAAA);
  static const _sublabel = Color(0xFF7B7B9D);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Auth actions ──────────────────────────────────────────────────
  // After a successful sign-in, an auth gate in main.dart listening to
  // FirebaseAuth.instance.authStateChanges() switches to the home screen,
  // so nothing needs to navigate from here.

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _emailLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_errMsg(e.code));
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _emailLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } else {
        // google_sign_in 7.x: initialize() must have been called once
        // in main() before this point.
        final account = await GoogleSignIn.instance.authenticate();
        final idToken = account.authentication.idToken;
        if (idToken == null) {
          _showError('Google sign-in failed. Please try again.');
          return;
        }
        await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }
    } on GoogleSignInException catch (e) {
      // User closed the account picker: not an error worth showing.
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _showError('Google sign-in failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'popup-closed-by-user') _showError(_errMsg(e.code));
    } catch (_) {
      _showError('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _facebookLoading = true);
    try {
      final provider = FacebookAuthProvider()..addScope('email');
      if (kIsWeb) {
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code != 'popup-closed-by-user' &&
          e.code != 'canceled' &&
          e.code != 'web-context-canceled') {
        _showError(_errMsg(e.code));
      }
    } catch (_) {
      _showError('Facebook sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _facebookLoading = false);
    }
  }

  void _forgotPassword() => Navigator.of(context).pushNamed('/forgot-password');

  void _goToSignUp() => Navigator.of(context).pushNamed('/signup');

  String _errMsg(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using another sign-in method.';
      default:
        return 'Login failed. ($code)';
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: MessLifeColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ));
  }

  // ── UI ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final top = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
      ),
      child: Scaffold(
        backgroundColor: MessLifeColors.background,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // ── Static header (logo only, no animation) ──────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: top + 24, bottom: 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [MessLifeColors.gradientStart, MessLifeColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: const Center(
                  child: MessLifeLogo(size: 120, rounded: true),
                ),
              ),

              // ── Form ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: h * 0.03),
                      const Text(
                        'Welcome to MessLife',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MessLifeColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Mess Finder & Manager',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _sublabel, fontSize: 13),
                      ),
                      SizedBox(height: h * 0.028),

                      _Field(
                        ctrl: _emailCtrl,
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                        type: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your email'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        ctrl: _passwordCtrl,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffix: GestureDetector(
                          onTap: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: _hint,
                            size: 19,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your password';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: MessLifeColors.ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _PrimaryBtn(
                        label: 'Sign In',
                        loading: _emailLoading,
                        onPressed: _busy ? null : _signInWithEmail,
                      ),
                      const SizedBox(height: 16),

                      const _OrDivider(),
                      const SizedBox(height: 14),

                      _OutlineBtn(
                        onPressed: _busy ? null : _signInWithGoogle,
                        loading: _googleLoading,
                        icon: const _GoogleLogo(),
                        label: 'Continue with Google',
                      ),
                      const SizedBox(height: 10),
                      _OutlineBtn(
                        onPressed: _busy ? null : _signInWithFacebook,
                        loading: _facebookLoading,
                        icon: const _FacebookLogo(),
                        label: 'Continue with Facebook',
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? ",
                              style: TextStyle(color: _sublabel, fontSize: 13)),
                          GestureDetector(
                            onTap: _busy ? null : _goToSignUp,
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: MessLifeColors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.type = TextInputType.text,
    this.obscure = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;

  OutlineInputBorder _b(Color c, double w) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c, width: w),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1A1A3E),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13.5),
        prefixIcon: Icon(icon, color: const Color(0xFF9999BB), size: 19),
        suffixIcon: suffix == null
            ? null
            : Padding(padding: const EdgeInsets.only(right: 10), child: suffix),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: _b(const Color(0xFFDDE1F5), 1.2),
        enabledBorder: _b(const Color(0xFFDDE1F5), 1.2),
        focusedBorder: _b(MessLifeColors.ink, 1.6),
        errorBorder: _b(MessLifeColors.red, 1.2),
        focusedErrorBorder: _b(MessLifeColors.red, 1.6),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: MessLifeColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: MessLifeColors.ink.withValues(alpha: .55),
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      )
          : Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: _LoginScreenState._border, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        padding: EdgeInsets.zero,
      ),
      child: loading
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: MessLifeColors.ink,
        ),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 9),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1A1A3E),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => const Row(children: [
    Expanded(child: Divider(color: Color(0xFFDDE1F5), thickness: 1, endIndent: 10)),
    Text('or', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12.5)),
    Expanded(child: Divider(color: Color(0xFFDDE1F5), thickness: 1, indent: 10)),
  ]);
}

class _FacebookLogo extends StatelessWidget {
  const _FacebookLogo();

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Color(0xFF1877F2),
      shape: BoxShape.circle,
    ),
    child: const Text(
      'f',
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w900,
        height: 1.15,
      ),
    ),
  );
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;
    final p = Paint()..style = PaintingStyle.fill;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    p.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.36, 1.57, true, p);
    p.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.36, 0.79, true, p);
    p.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.14, 1.18, true, p);
    p.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.79, 1.18, true, p);

    canvas.drawCircle(Offset(cx, cy), r * 0.58, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - r * 0.02, cy - r * 0.22, cx + r * 1.02, cy + r * 0.22),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawCircle(Offset(cx, cy), r * 0.44, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}