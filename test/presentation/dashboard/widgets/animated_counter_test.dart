import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/presentation/dashboard/widgets/animated_counter.dart';

void main() {
  group('AnimatedCounter Widget', () {
    testWidgets('displays initial value correctly', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 100.50,
              prefix: '\$',
              suffix: ' USD',
              decimalPlaces: 2,
            ),
          ),
        ),
      );

      // Find the text widget
      expect(find.byType(AnimatedCounter), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
      
      // Initially should show 0 as animation starts from 0
      expect(find.text('\$0.00 USD'), findsOneWidget);
    });

    testWidgets('animates to target value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 100.0,
              prefix: '\$',
              decimalPlaces: 0,
              duration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Initially shows 0
      expect(find.text('\$0'), findsOneWidget);

      // Pump the animation to completion
      await tester.pumpAndSettle();

      // Should now show the final value
      expect(find.text('\$100'), findsOneWidget);
    });

    testWidgets('updates when value changes', (WidgetTester tester) async {
      double testValue = 50.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedCounter(
                      value: testValue,
                      prefix: '\$',
                      decimalPlaces: 0,
                      duration: const Duration(milliseconds: 100),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          testValue = 100.0;
                        });
                      },
                      child: const Text('Update'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Wait for initial animation
      await tester.pumpAndSettle();
      expect(find.text('\$50'), findsOneWidget);

      // Tap the update button
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      // Should show updated value
      expect(find.text('\$100'), findsOneWidget);
    });

    testWidgets('respects decimal places parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 123.456789,
              decimalPlaces: 3,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should format to 3 decimal places
      expect(find.text('123.457'), findsOneWidget);
    });

    testWidgets('handles zero decimal places', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 99.9,
              decimalPlaces: 0,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should format as integer
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('applies custom text style', (WidgetTester tester) async {
      const customStyle = TextStyle(
        fontSize: 24,
        color: Colors.red,
        fontWeight: FontWeight.bold,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 42.0,
              style: customStyle,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style, customStyle);
    });

    testWidgets('handles negative values', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: -50.25,
              prefix: '-\$',
              decimalPlaces: 2,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('-\$-50.25'), findsOneWidget);
    });

    testWidgets('handles very large numbers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 1234567.89,
              decimalPlaces: 2,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1234567.89'), findsOneWidget);
    });

    testWidgets('works without prefix and suffix', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 25.0,
              decimalPlaces: 1,
              duration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('25.0'), findsOneWidget);
    });
  });
}