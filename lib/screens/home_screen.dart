// File: lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

/// Post-login home: the mess dashboard.
/// Kept as HomeScreen so AuthFlow and guest_dashboard_screen.dart
/// keep working without changes.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const DashboardScreen();
}