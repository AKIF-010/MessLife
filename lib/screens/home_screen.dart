import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/language_controller.dart';
import '../services/auth_service.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgTop,
        elevation: 0,
        title: const MessLifeLogo(size: 22),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: LanguageToggle()),
          ),
        ],
      ),
      body: AuthBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('homeWelcome'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.email ?? user?.displayName ?? '',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  child: PrimaryButton(
                    label: context.tr('signOut'),
                    onPressed: () async {
                      await AuthService.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}