// File: lib/screens/forgot_password_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl = TextEditingController(
    text: widget.initialEmail,
  );
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordReset(_emailCtrl.text);
      if (!mounted) return;
      showAppSnack(context, context.tr('resetSent'), error: false);
      Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          GradientHeader(
            child: HeaderTitleRow(
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: _loading ? null : () => Navigator.of(context).pop(),
              ),
              title: context.tr('resetTitle'),
              trailing: const LanguageToggle(onDark: true),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('resetSubtitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Form(
                          key: _formKey,
                          child: AppTextField(
                            label: context.tr('emailLabel'),
                            hint: context.tr('emailHint'),
                            controller: _emailCtrl,
                            icon: Icons.mail_outline_rounded,
                            enabled: !_loading,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _send(),
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return context.tr('emailRequired');
                              if (!emailRegex.hasMatch(t)) {
                                return context.tr('emailInvalid');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: context.tr('sendReset'),
                          loading: _loading,
                          onPressed: _send,
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _loading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              context.tr('backToLogin'),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
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
    );
  }
}