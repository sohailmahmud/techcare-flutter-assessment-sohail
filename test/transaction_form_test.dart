import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fintrack/presentation/transactions/form/pages/add_edit_transaction_screen.dart';
import 'package:fintrack/injection_container.dart' as di;

void main() {
  group('Transaction Form Tests', () {
    setUpAll(() async {
      // Initialize dependency injection
      await di.init();
    });

    testWidgets('Add Transaction Screen renders correctly', (WidgetTester tester) async {
      // Create the screen
      await tester.pumpWidget(
        MaterialApp(
          home: const AddEditTransactionScreen(),
        ),
      );

      // Let the screen render
      await tester.pump();

      // Verify key elements are present
      expect(find.text('Add Transaction'), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets); // Amount input field
      
      // Verify that the screen builds without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Transaction Type Selector works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AddEditTransactionScreen(),
        ),
      );

      await tester.pump();
      
      // Look for Income/Expense toggle buttons
      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      
      // Verify that the screen builds without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Category Selector displays categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AddEditTransactionScreen(),
        ),
      );

      await tester.pump();
      
      // Look for category section
      expect(find.text('Category'), findsOneWidget);
      
      // Should show expense categories by default
      expect(find.text('Food'), findsOneWidget);
      
      // Verify that the screen builds without errors
      expect(tester.takeException(), isNull);
    });
  });
}