import 'package:intl/intl.dart';

/// Utility class for formatting currency
class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  /// Format a number as currency
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format with compact notation (e.g., $1.2K, $1.5M)
  static String formatCompact(double amount) {
    final formatter = NumberFormat.compactCurrency(
      symbol: '\$',
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }

  // Private constructor
  CurrencyFormatter._();
}

/// Utility class for formatting dates
class DateFormatter {
  /// Format date as 'MMM dd, yyyy' (e.g., Jan 15, 2024)
  static String formatDisplay(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date and time as 'MMM dd, yyyy hh:mm a'
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy hh:mm a').format(date);
  }

  /// Format date for API as 'yyyy-MM-dd'
  static String formatApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format time as 'hh:mm a'
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Get relative time (e.g., "2 hours ago", "Yesterday")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDisplay(date);
    }
  }

  // Private constructor
  DateFormatter._();
}

/// Utility class for validations
class Validators {
  
/// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Enter a valid amount';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength,
      [String fieldName = 'Field']) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  // Private constructor
  Validators._();
}
