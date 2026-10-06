import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:messlife/login_screen.dart';
import 'package:messlife/messlife_theme.dart';

void main() {
  testWidgets('Login screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: messLifeTheme, home: const LoginScreen()),
    );
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}