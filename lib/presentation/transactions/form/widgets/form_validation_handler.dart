/// Comprehensive form validation handler for transaction forms
class FormValidationHandler {
  static const double _maxAmount = 1000000000; // 1 billion limit
  static const int _minTitleLength = 1;
  static const int _maxTitleLength = 100;
  static const int _maxDescriptionLength = 500;

  /// Validate amount field
  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    // Remove commas and currency symbols for parsing
    final cleanValue = value.replaceAll(RegExp(r'[৳,\s]'), '');

    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    if (amount > _maxAmount) {
      return 'Amount cannot exceed ৳${_formatNumber(_maxAmount)}';
    }

    return null;
  }

  /// Validate title field
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Transaction title is required';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < _minTitleLength) {
      return 'Title must be at least $_minTitleLength character';
    }

    if (trimmedValue.length > _maxTitleLength) {
      return 'Title cannot exceed $_maxTitleLength characters';
    }

    return null;
  }

  /// Validate description field (optional)
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }

    if (value.trim().length > _maxDescriptionLength) {
      return 'Description cannot exceed $_maxDescriptionLength characters';
    }

    return null;
  }

  /// Validate selected category
  static String? validateCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return 'Please select a category';
    }
    return null;
  }

  /// Validate transaction date
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }

    final now = DateTime.now();
    final maxFutureDate = now.add(const Duration(days: 1));

    if (date.isAfter(maxFutureDate)) {
      return 'Transaction date cannot be in the future';
    }

    final minPastDate = DateTime(2020, 1, 1);
    if (date.isBefore(minPastDate)) {
      return 'Transaction date is too far in the past';
    }

    return null;
  }

  /// Get form validation status
  static FormValidationStatus getValidationStatus({
    required String? amount,
    required String? title,
    required String? categoryId,
    required DateTime? date,
    String? description,
  }) {
    final errors = <String, String>{};

    final amountError = validateAmount(amount);
    if (amountError != null) errors['amount'] = amountError;

    final titleError = validateTitle(title);
    if (titleError != null) errors['title'] = titleError;

    final categoryError = validateCategory(categoryId);
    if (categoryError != null) errors['category'] = categoryError;

    final dateError = validateDate(date);
    if (dateError != null) errors['date'] = dateError;

    final descriptionError = validateDescription(description);
    if (descriptionError != null) errors['description'] = descriptionError;

    return FormValidationStatus(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// Format number with commas
  static String _formatNumber(double number) {
    return number.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  /// Clean and parse amount string
  static double parseAmount(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[৳,\s]'), '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  /// Format amount for display
  static String formatAmountForDisplay(double amount) {
    return '৳${_formatNumber(amount)}';
  }

  /// Real-time validation state
  static bool isValidAmountInput(String value) {
    if (value.isEmpty) return true; // Allow empty during typing
    final cleanValue = value.replaceAll(RegExp(r'[৳,\s]'), '');
    final amount = double.tryParse(cleanValue);
    return amount != null && amount >= 0;
  }

  /// Check if title has valid length during typing
  static bool isValidTitleInput(String value) {
    return value.length <= _maxTitleLength;
  }

  /// Check if description has valid length during typing
  static bool isValidDescriptionInput(String value) {
    return value.length <= _maxDescriptionLength;
  }
}

/// Form validation status model
class FormValidationStatus {
  final bool isValid;
  final Map<String, String> errors;

  const FormValidationStatus({
    required this.isValid,
    required this.errors,
  });

  String? getError(String field) => errors[field];
  bool hasError(String field) => errors.containsKey(field);
  int get errorCount => errors.length;
}

/// Form field validation result
class FieldValidationResult {
  final bool isValid;
  final String? error;

  const FieldValidationResult({
    required this.isValid,
    this.error,
  });

  factory FieldValidationResult.valid() {
    return const FieldValidationResult(isValid: true);
  }

  factory FieldValidationResult.invalid(String error) {
    return FieldValidationResult(isValid: false, error: error);
  }
}
