// File: lib/screens/guest_dashboard_screen.dart
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../services/auth_flow.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'placeholder_screens.dart';

/// First screen for everyone who is not signed in. No login needed here.
class GuestDashboardScreen extends StatelessWidget {
  const GuestDashboardScreen({super.key});

  Future<void> _gated(
      BuildContext context, {
        required String reasonKey,
        required String titleKey,
      }) async {
    final ok = await AuthFlow.ensureReady(context, reasonKey: reasonKey);
    if (ok && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ComingSoonScreen(titleKey: titleKey)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          GradientHeader(
            bottomRadius: 30,
            bottomPadding: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [BrandTile(size: 50), LanguageToggle(onDark: true)],
                ),
                const SizedBox(height: 18),
                const Text(
                  'MESSLIFE BD',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mintText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('dashTitle'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('dashSubtitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mintText,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FieldLabel(context.tr('dashAsk')),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.search_rounded,
                          title: context.tr('findMess'),
                          subtitle: context.tr('findMessSub'),
                          color: AppColors.cardMint,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const FindMessScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.home_outlined,
                          title: context.tr('createMess'),
                          subtitle: context.tr('createMessSub'),
                          color: AppColors.cardMint,
                          onTap: () => _gated(
                            context,
                            reasonKey: 'reasonCreate',
                            titleKey: 'createMess',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionCard(
                          icon: Icons.lock_outline_rounded,
                          title: context.tr('joinCode'),
                          subtitle: context.tr('joinCodeSub'),
                          color: AppColors.cardMintAlt,
                          onTap: () => _gated(
                            context,
                            reasonKey: 'reasonJoin',
                            titleKey: 'joinCode',
                          ),
                        ),
                        const SizedBox(height: 22),
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
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
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
                        if (kDebugMode) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.mintBorder),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Text(
                                  context.tr('developer'),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.2,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: AppColors.mintBorder),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DashedBorderBox(
                            fill: AppColors.fieldFill,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('skipDashboard'),
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}