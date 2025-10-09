// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fintrack/main.dart';
import 'package:fintrack/injection_container.dart' as di;

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    // Initialize dependency injection
    await di.init();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinTrackApp());

    // Wait for initial render
    await tester.pump();

    // Verify that the bottom navigation bar is present
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify that all three tabs are present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
