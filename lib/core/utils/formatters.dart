import 'package:intl/intl.dart';

/// Utility class for formatting currency
class CurrencyFormatter {
  // Private constructor
  const CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '৳',
    decimalDigits: 0, // Taka typically doesn't use decimal places
  );

  /// Format a number as currency
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Format with compact notation (e.g., ৳1.2K, ৳1.5M)
  static String formatCompact(double amount) {
    final formatter = NumberFormat.compactCurrency(
      symbol: '৳',
      decimalDigits: 1,
    );
    return formatter.format(amount);
  }
}

/// Utility class for formatting dates
class DateFormatter {
  // Private constructor
  const DateFormatter._();

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

  /// Format date for grouping transactions (e.g., "Today", "Yesterday", "Jan 15")
  static String formatDateGrouping(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (transactionDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (transactionDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      // Same year: show only month and day
      return DateFormat('MMM dd').format(date);
    } else {
      // Different year: show month, day, and year
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
