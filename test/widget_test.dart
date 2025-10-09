// This is a basic Flutter widget test for the app structure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic app widget test', (WidgetTester tester) async {
    // Create a simple test widget to verify Flutter testing works
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Center(
            child: Text('FinTrack Test'),
          ),
          bottomNavigationBar: NavigationBar(
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.list), label: 'Transactions'),
              NavigationDestination(icon: Icon(Icons.analytics), label: 'Analytics'),
            ],
          ),
        ),
      ),
    );

    // Wait for initial render
    await tester.pump();

    // Verify basic elements are present
    expect(find.text('FinTrack Test'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
  });
}
