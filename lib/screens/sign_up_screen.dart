// File: lib/screens/sign_up_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../services/auth_flow.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/common_widgets.dart';
import '../widgets/phone_field.dart';

/// Step 1 of 2: your details. Step 2 is the email verification page.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  Country _phoneCountry = kBangladesh;
  String? _gender; // "male" | "female"
  bool _genderError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState!.validate();
    setState(() => _genderError = _gender == null);
    if (!valid || _gender == null) return;

    setState(() => _loading = true);
    try {
      final locale = LanguageScope.of(context).code;
      final cred = await AuthService.instance.createAccount(
        _emailCtrl.text,
        _passCtrl.text,
      );
      final user = cred.user;
      if (user != null) {
        // If saving fails now, AuthFlow creates a base profile later and the
        // registration screen simply asks for the missing details again.
        try {
          await UserService.instance.ensureProfile(
            user,
            fullName: _nameCtrl.text.trim(),
            phone: PhoneRules.toE164(_phoneCountry, _phoneCtrl.text),
            gender: _gender,
            provider: 'email',
            locale: locale,
          );
        } catch (_) {}
        try {
          await AuthService.instance.sendEmailVerification();
        } catch (_) {}
      }
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
              title: context.tr('signUpTitle'),
              subtitle: context.tr('signUpSubtitle'),
              trailing: const StepDots(total: 2, current: 0),
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
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              AppTextField(
                                label: context.tr('fullName'),
                                hint: context.tr('fullNameHint'),
                                controller: _nameCtrl,
                                enabled: !_loading,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                validator: (v) =>
                                (v?.trim().length ?? 0) < 2
                                    ? context.tr('nameRequired')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: context.tr('emailLabel'),
                                hint: context.tr('emailHint'),
                                controller: _emailCtrl,
                                enabled: !_loading,
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
                              const SizedBox(height: 14),
                              PhoneField(
                                label: context.tr('phoneLabel'),
                                controller: _phoneCtrl,
                                country: _phoneCountry,
                                onCountryChanged: (c) => setState(() => _phoneCountry = c),
                                enabled: !_loading,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.telephoneNumber],
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: context.tr('passwordLabel'),
                                hint: context.tr('passwordHintNew'),
                                controller: _passCtrl,
                                enabled: !_loading,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
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
                                validator: (v) {
                                  final t = v ?? '';
                                  if (t.isEmpty) {
                                    return context.tr('passwordRequired');
                                  }
                                  if (t.length < 8) {
                                    return context.tr('passwordShort');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              AppTextField(
                                label: context.tr('confirmPassword'),
                                hint: context.tr('confirmHint'),
                                controller: _confirmCtrl,
                                enabled: !_loading,
                                obscureText: _obscure,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _create(),
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
                                validator: (v) => v != _passCtrl.text
                                    ? context.tr('passwordsMismatch')
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FieldLabel(context.tr('gender')),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceTile(
                                label: context.tr('male'),
                                emoji: '🧑',
                                center: true,
                                expand: true,
                                selected: _gender == 'male',
                                onTap: _loading
                                    ? () {}
                                    : () => setState(() {
                                  _gender = 'male';
                                  _genderError = false;
                                }),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ChoiceTile(
                                label: context.tr('female'),
                                emoji: '👩',
                                center: true,
                                expand: true,
                                selected: _gender == 'female',
                                onTap: _loading
                                    ? () {}
                                    : () => setState(() {
                                  _gender = 'female';
                                  _genderError = false;
                                }),
                              ),
                            ),
                          ],
                        ),
                        if (_genderError)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              context.tr('genderRequired'),
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: '${context.tr('continueBtn')} →',
                          loading: _loading,
                          onPressed: _create,
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                context.tr('haveAccount'),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: _loading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Text(
                                    context.tr('signIn'),
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
    );
  }
}