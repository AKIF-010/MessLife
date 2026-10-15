import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:messlife/main.dart';

void main() {
  testWidgets('MessLife app builds', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const MessLifeApp());

    // Let the startup delay in main.dart run.
    await tester.pump(const Duration(seconds: 1));

    // The app should be showing a MaterialApp.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}