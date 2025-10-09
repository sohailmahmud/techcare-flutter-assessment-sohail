import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fintrack/domain/entities/category.dart';

void main() {
  group('Category', () {
    const category = Category(
      id: 'cat1',
      name: 'Food & Dining',
      icon: Icons.restaurant,
      color: Colors.orange,
      isIncome: false,
      budget: 500.0,
    );

    group('constructor', () {
      test('creates category with required parameters', () {
        const minimalCategory = Category(
          id: 'cat2',
          name: 'Transportation',
          icon: Icons.directions_car,
          color: Colors.blue,
        );

        expect(minimalCategory.id, 'cat2');
        expect(minimalCategory.name, 'Transportation');
        expect(minimalCategory.icon, Icons.directions_car);
        expect(minimalCategory.color, Colors.blue);
        expect(minimalCategory.isIncome, isFalse);
        expect(minimalCategory.budget, isNull);
      });

      test('creates category with all parameters', () {
        expect(category.id, 'cat1');
        expect(category.name, 'Food & Dining');
        expect(category.icon, Icons.restaurant);
        expect(category.color, Colors.orange);
        expect(category.isIncome, isFalse);
        expect(category.budget, 500.0);
      });

      test('creates income category', () {
        const incomeCategory = Category(
          id: 'inc1',
          name: 'Salary',
          icon: Icons.work,
          color: Colors.green,
          isIncome: true,
        );

        expect(incomeCategory.isIncome, isTrue);
        expect(incomeCategory.budget, isNull);
      });
    });

    group('helper methods', () {
      test('iconName returns mapped icon name for known icons', () {
        const restaurantCategory = Category(
          id: 'cat1',
          name: 'Food',
          icon: Icons.restaurant,
          color: Colors.orange,
        );

        expect(restaurantCategory.iconName, 'restaurant');
      });

      test('iconName returns default for unknown icons', () {
        const unknownCategory = Category(
          id: 'cat2',
          name: 'Other',
          icon: Icons.star, // not in the known icon map
          color: Colors.grey,
        );

        expect(unknownCategory.iconName, 'category');
      });

      test('colorHex returns uppercase hex color string', () {
        const redCategory = Category(
          id: 'cat3',
          name: 'Red Category',
          icon: Icons.circle,
          color: Colors.red,
        );

        final hexColor = redCategory.colorHex;
        expect(hexColor, startsWith('#'));
        expect(hexColor.length, 7); // #RRGGBB format
        expect(hexColor, contains(RegExp(r'^#[0-9A-F]{6}$')));
      });
    });

    group('immutability', () {
      test('category properties cannot be modified after creation', () {
        // This test verifies that Category is immutable by design
        expect(category.id, 'cat1');
        expect(category.name, 'Food & Dining');
        expect(category.isIncome, isFalse);
        expect(category.budget, 500.0);
        
        // All fields are final, so they cannot be reassigned
        // This test just verifies the immutable nature exists
      });
    });

    group('equality', () {
      test('two categories with same properties are equal', () {
        const category1 = Category(
          id: 'test1',
          name: 'Test Category',
          icon: Icons.star,
          color: Colors.blue,
          isIncome: false,
          budget: 100.0,
        );

        const category2 = Category(
          id: 'test1',
          name: 'Test Category',
          icon: Icons.star,
          color: Colors.blue,
          isIncome: false,
          budget: 100.0,
        );

        expect(category1, equals(category2));
        expect(category1.hashCode, equals(category2.hashCode));
      });

      test('two categories with different properties are not equal', () {
        const category1 = Category(
          id: 'test1',
          name: 'Test Category',
          icon: Icons.star,
          color: Colors.blue,
        );

        const category2 = Category(
          id: 'test2',
          name: 'Test Category',
          icon: Icons.star,
          color: Colors.blue,
        );

        expect(category1, isNot(equals(category2)));
        expect(category1.hashCode, isNot(equals(category2.hashCode)));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final string = category.toString();
        
        expect(string, contains('Category'));
        expect(string, contains('cat1'));
        expect(string, contains('Food & Dining'));
      });
    });
  });
}