// File: lib/screens/verify_email_screen.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../services/auth_flow.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

/// Step 2 of 2: waits until the email link is opened. Checks automatically.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _cooldownSeconds = 60;

  Timer? _poll;
  Timer? _tick;
  bool _checking = false;
  bool _manualLoading = false;
  bool _resending = false;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(
      const Duration(seconds: 4),
          (_) => _check(silent: true),
    );
    // First check right away (e.g. user verified on another device).
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    _checking = true;
    if (!silent && mounted) setState(() => _manualLoading = true);
    try {
      final user = await AuthService.instance.reloadUser();
      if (!mounted) return;
      if (user != null && AuthService.instance.isEmailTrusted(user)) {
        _poll?.cancel();
        await AuthFlow.advance();
        return;
      }
      if (!silent) {
        showAppSnack(context, context.tr('verifyNotYet'));
      }
    } on FirebaseAuthException catch (e) {
      if (!silent && mounted) {
        showAppSnack(context, context.tr(authErrorKey(e.code)));
      }
    } catch (_) {
      if (!silent && mounted) {
        showAppSnack(context, context.tr('errGeneric'));
      }
    } finally {
      _checking = false;
      if (mounted && _manualLoading) setState(() => _manualLoading = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() => _resending = true);
    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) return;
      showAppSnack(context, context.tr('verifyResent'), error: false);
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showAppSnack(context, context.tr(authErrorKey(e.code)));
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, context.tr('errGeneric'));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    _tick?.cancel();
    setState(() => _cooldown = _cooldownSeconds);
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _useDifferentAccount() async {
    _poll?.cancel();
    await AuthService.instance.signOut();
    AuthFlow.navKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? '';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AuthFlow.cancel();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            GradientHeader(
              child: HeaderTitleRow(
                leading: const BrandTile(),
                title: context.tr('verifyTitle'),
                subtitle: context.tr('verifySubtitle'),
                trailing: const StepDots(total: 2, current: 1),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: const BoxDecoration(
                              color: AppColors.cardMint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_unread_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            context.tr('verifySent'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.tr('verifyHelp'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 28),
                          PrimaryButton(
                            label: context.tr('verifiedBtn'),
                            loading: _manualLoading,
                            onPressed: () => _check(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: (_cooldown > 0 || _resending)
                                  ? null
                                  : _resend,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: AppColors.mintBorder,
                                  width: 1.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _resending
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.primary,
                                ),
                              )
                                  : Text(
                                _cooldown > 0
                                    ? context
                                    .tr('resendIn')
                                    .replaceAll('{s}', '$_cooldown')
                                    : context.tr('resendEmail'),
                                style: const TextStyle(
                                  color: AppColors.dark,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _useDifferentAccount,
                            child: Text(
                              context.tr('useDifferent'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
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