// File: lib/screens/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../services/auth_flow.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;
  bool _googleLoading = false;

  bool get _busy => _loading || _googleLoading;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.signInWithEmail(
        _emailCtrl.text,
        _passCtrl.text,
        remember: _remember,
      );
      await AuthFlow.advance();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.tr(authErrorKey(e.code)));
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, context.tr('errGeneric'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _googleLoading = true);
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result != null) await AuthFlow.advance();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.tr(authErrorKey(e.code)));
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, context.tr('errGoogle'));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = AuthFlow.reasonKey;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        // User backed out of a gated login: tell the caller "not signed in".
        if (didPop && AuthService.instance.currentUser == null) {
          AuthFlow.abort();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            GradientHeader(
              child: HeaderTitleRow(
                leading: const BrandTile(),
                title: context.tr('loginTitle'),
                subtitle: context.tr('loginSubtitle'),
                trailing: const LanguageToggle(onDark: true),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Banner(
                            text: context.tr(reason ?? 'loginBanner'),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                AppTextField(
                                  label: context.tr('emailLabel'),
                                  hint: context.tr('emailHint'),
                                  controller: _emailCtrl,
                                  icon: Icons.mail_outline_rounded,
                                  enabled: !_busy,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: (v) {
                                    final t = v?.trim() ?? '';
                                    if (t.isEmpty) {
                                      return context.tr('emailRequired');
                                    }
                                    if (!emailRegex.hasMatch(t)) {
                                      return context.tr('emailInvalid');
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  label: context.tr('passwordLabel'),
                                  hint: context.tr('passwordHint'),
                                  controller: _passCtrl,
                                  icon: Icons.lock_outline_rounded,
                                  enabled: !_busy,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onSubmitted: (_) => _signIn(),
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.muted,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                  // Only "required": old accounts may have
                                  // shorter passwords than the new 8-char rule.
                                  validator: (v) => (v ?? '').isEmpty
                                      ? context.tr('passwordRequired')
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: Checkbox(
                                  value: _remember,
                                  activeColor: AppColors.primary,
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: _busy
                                      ? null
                                      : (v) =>
                                      setState(() => _remember = v ?? true),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('rememberMe'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.dark,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPasswordScreen(
                                      initialEmail: _emailCtrl.text.trim(),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  context.tr('forgotPassword'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PrimaryButton(
                            label: context.tr('signIn'),
                            loading: _loading,
                            onPressed: _busy ? null : _signIn,
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.mintBorder),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  context.tr('orContinueWith'),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: AppColors.mintBorder),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: SocialButton(
                              icon: Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: AppColors.dark,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              label: context.tr('continueGoogle'),
                              loading: _googleLoading,
                              onPressed: _busy ? null : _google,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  context.tr('noAccount'),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _busy
                                      ? null
                                      : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpScreen(),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      context.tr('signUp'),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardMint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.mintBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.dark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}