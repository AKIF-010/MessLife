// File: lib/screens/placeholder_screens.dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../services/auth_flow.dart';
import '../widgets/common_widgets.dart';

/// Temporary "Find a Mess" screen. Guests can open it without login.
/// Replace the body with the real map / filters / list later.
class FindMessScreen extends StatelessWidget {
  const FindMessScreen({super.key});

  Future<void> _chatDemo(BuildContext context) async {
    final ok = await AuthFlow.ensureReady(context, reasonKey: 'reasonChat');
    if (ok && context.mounted) {
      showAppSnack(context, context.tr('chatDemoOk'), error: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerStart,
        foregroundColor: Colors.white,
        title: Text(
          context.tr('findMess'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: LanguageToggle(onDark: true)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 14),
              Text(
                context.tr('findMessSoon'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: 260,
                  child: PrimaryButton(
                    label: context.tr('chatDemo'),
                    onPressed: () => _chatDemo(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic placeholder for screens built in later steps.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.titleKey});
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.headerStart,
        foregroundColor: Colors.white,
        title: Text(
          context.tr(titleKey),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('comingSoon'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('comingSoonBody'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}