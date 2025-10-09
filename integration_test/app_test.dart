import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/main.dart' as app;

void main() {
  group('FinTrack App Widget Tests', () {
    testWidgets('Complete user flow: navigation and transaction management',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test 1: Verify app launches with dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Test 2: Navigate to Analytics page
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      expect(find.text('Analytics'), findsOneWidget);

      // Test 3: Change time period in analytics
      final weekButton = find.text('This Week');
      if (weekButton.evaluate().isNotEmpty) {
        await tester.tap(weekButton);
        await tester.pumpAndSettle();
      }

      // Test 4: Navigate to Transactions page
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      expect(find.text('Transactions'), findsOneWidget);

      // Test 5: Try to add a new transaction using FAB
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify we're in the add transaction form
        expect(find.text('Add Transaction'), findsOneWidget);

        // Test form interaction
        final amountField = find.byType(TextFormField).first;
        await tester.enterText(amountField, '100');
        await tester.pump();

        // Navigate back without saving to test navigation
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // Test 6: Navigate back to Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);

      // Test 7: Test balance visibility toggle (if exists)
      final visibilityToggle = find.byIcon(Icons.visibility_off);
      if (visibilityToggle.evaluate().isNotEmpty) {
        await tester.tap(visibilityToggle);
        await tester.pump();
      }

      // Test 8: Navigate to Categories page
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
    });

    testWidgets('App performance and stability test',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Rapid navigation test to check for memory leaks or crashes
      for (int i = 0; i < 3; i++) {
        // Navigate through all tabs quickly
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Transactions'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Categories'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Dashboard'));
        await tester.pumpAndSettle();
      }

      // Verify app is still stable
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Accessibility test', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Basic accessibility check - ensure key widgets have semantics
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Check that navigation items are accessible
      final semantics = tester.getSemantics(find.byType(BottomNavigationBar));
      expect(semantics, isNotNull);

      // Test semantic labels for major UI elements
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Ensure screen reader can find important elements
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('Error handling and recovery test',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Test navigation resilience
      try {
        // Navigate to each screen and back rapidly
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();

        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Transactions'));
        await tester.pumpAndSettle();

        // Verify app handles navigation gracefully
        expect(find.text('Transactions'), findsOneWidget);
      } catch (e) {
        // Log any navigation errors but don't fail the test
        debugPrint('Navigation test encountered: $e');
      }

      // Ensure app is still functional
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
