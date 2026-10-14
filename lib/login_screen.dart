// lib/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'messlife_logo.dart';
import 'messlife_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscurePassword = true;
  final bool _isLoading       = false;
  final bool _googleLoading   = false;

  static const _primary   = MessLifeColors.ink;
  static const _bg        = MessLifeColors.background;
  static const _border    = Color(0xFFDDE3EF);
  static const _hint      = Color(0xFFAAAAAA);
  static const _label     = Color(0xFF0F2A52);
  static const _sublabel  = Color(0xFF6B7A90);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // UI only for now - no backend connected yet.
  void _signInWithEmail() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: connect email/password sign-in
  }

  void _signInWithGoogle() {
    // TODO: connect Google sign-in
  }

  void _forgotPassword() {
    // TODO: navigate to forgot-password screen
  }

  void _goToSignUp() {
    // TODO: navigate to sign-up screen
  }

  @override
  Widget build(BuildContext context) {
    final sz      = MediaQuery.of(context).size;
    final h       = sz.height;
    final w       = sz.width;
    final headerH = h * 0.27;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MessLifeColors.gradientStart,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark,      // iOS
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            // status-bar background
            Container(
              color: MessLifeColors.gradientStart,
              height: MediaQuery.of(context).padding.top,
            ),

            // ── Static logo header (no animation) ───────────────
            Container(
              width: double.infinity,
              height: headerH,
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
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GlowPainter())),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: MessLifeLogo(
                        size: (headerH * 0.62).clamp(80.0, 130.0),
                        rounded: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: h * 0.025),

                      const Text('Welcome to MessLife BD',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _label, fontSize: 20,
                              fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                      const SizedBox(height: 3),
                      const Text('Mess Finder & Manager',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _sublabel, fontSize: 13)),
                      SizedBox(height: h * 0.022),

                      _Field(
                        ctrl: _emailCtrl,
                        hint: 'Email',
                        icon: Icons.mail_outline_rounded,
                        type: TextInputType.emailAddress,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your email' : null,
                      ),
                      SizedBox(height: h * 0.012),

                      _Field(
                        ctrl:    _passwordCtrl,
                        hint:    'Password',
                        icon:    Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffix: GestureDetector(
                          onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                          child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _hint, size: 19),
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
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize:   Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Forgot password?',
                              style: TextStyle(color: _primary,
                                  fontSize: 12.5, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      SizedBox(height: h * 0.012),

                      // Sign In
                      _PrimaryBtn(
                          label: 'Sign In',
                          loading: _isLoading,
                          onPressed: _signInWithEmail),
                      SizedBox(height: h * 0.016),

                      const _OrDivider(),
                      SizedBox(height: h * 0.014),

                      // Google
                      _OutlineBtn(
                        onPressed:   _googleLoading ? null : _signInWithGoogle,
                        loading:     _googleLoading,
                        icon:        const _GoogleLogo(),
                        label:       'Continue with Google',
                        borderColor: _border,
                      ),
                      SizedBox(height: h * 0.022),

                      // Sign Up
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(color: _sublabel, fontSize: 13)),
                        GestureDetector(
                          onTap: _goToSignUp,
                          child: const Text('Sign Up',
                              style: TextStyle(color: _primary,
                                  fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      SizedBox(height: h * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Rect.fromLTWH(0, 0, s.width, s.height),
        Paint()..shader = RadialGradient(
          center: Alignment.center, radius: 0.65,
          colors: [
            const Color(0xFFFF7B3D).withValues(alpha: 0.20),
            const Color(0xFFFF7B3D).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, s.width, s.height)));
  }
  @override bool shouldRepaint(_) => false;
}

class _Field extends StatelessWidget {
  const _Field({required this.ctrl, required this.hint, required this.icon,
    this.type = TextInputType.text, this.obscure = false,
    this.suffix, this.validator});
  final TextEditingController ctrl; final String hint; final IconData icon;
  final TextInputType type; final bool obscure;
  final Widget? suffix; final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl, keyboardType: type,
      obscureText: obscure, validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A3E),
          fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13.5),
        prefixIcon: Icon(icon, color: const Color(0xFF9999BB), size: 19),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 10), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE3EF), width: 1.2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDE3EF), width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: MessLifeColors.ink, width: 1.6)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.6)),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label, required this.onPressed, this.loading = false});
  final String label; final VoidCallback onPressed; final bool loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 48,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: MessLifeColors.ink, foregroundColor: Colors.white,
          disabledBackgroundColor: MessLifeColors.ink.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0),
      child: loading
          ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: const TextStyle(fontSize: 15,
          fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.onPressed, required this.icon,
    required this.label, required this.borderColor, this.loading = false});
  final VoidCallback? onPressed; final Widget icon;
  final String label; final Color borderColor; final bool loading;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 46,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: borderColor, width: 1.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0, padding: EdgeInsets.zero),
      child: loading
          ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: MessLifeColors.ink))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon, const SizedBox(width: 9),
        Text(label, style: const TextStyle(color: Color(0xFF1A1A3E),
            fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) => const Row(children: [
    Expanded(child: Divider(color: Color(0xFFDDE3EF), thickness: 1, endIndent: 10)),
    Text('or', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12.5)),
    Expanded(child: Divider(color: Color(0xFFDDE3EF), thickness: 1, indent: 10)),
  ]);
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 20, height: 20,
          child: CustomPaint(painter: _GoogleLogoPainter()));
}

class _GoogleLogoPainter extends CustomPainter {
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
          Rect.fromLTRB(cx - r*0.02, cy - r*0.22, cx + r*1.02, cy + r*0.22),
          const Radius.circular(2)),
      Paint()..color = const Color(0xFF4285F4),
    );
    canvas.drawCircle(Offset(cx, cy), r * 0.44, Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(_) => false;
}