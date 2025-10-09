import 'package:equatable/equatable.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../domain/entities/category.dart';

/// Form validation errors
enum TransactionFormError {
  amountRequired,
  amountMustBePositive,
  titleRequired,
  titleTooLong,
  categoryRequired,
  dateInFuture,
  notesTooLong,
}

extension TransactionFormErrorExtension on TransactionFormError {
  String get message {
    switch (this) {
      case TransactionFormError.amountRequired:
        return 'Amount is required';
      case TransactionFormError.amountMustBePositive:
        return 'Amount must be greater than zero';
      case TransactionFormError.titleRequired:
        return 'Title is required';
      case TransactionFormError.titleTooLong:
        return 'Title must be 100 characters or less';
      case TransactionFormError.categoryRequired:
        return 'Please select a category';
      case TransactionFormError.dateInFuture:
        return 'Date cannot be in the future';
      case TransactionFormError.notesTooLong:
        return 'Notes must be 500 characters or less';
    }
  }
}

/// Transaction form data model
class TransactionFormData extends Equatable {
  final String? id; // null for new transaction
  final String amount;
  final String title;
  final String? notes;
  final TransactionType type;
  final Category? selectedCategory;
  final DateTime date;
  final DateTime time;

  const TransactionFormData({
    this.id,
    this.amount = '',
    this.title = '',
    this.notes,
    this.type = TransactionType.expense,
    this.selectedCategory,
    required this.date,
    required this.time,
  });

  factory TransactionFormData.initial() {
    final now = DateTime.now();
    return TransactionFormData(
      date: now,
      time: now,
    );
  }

  factory TransactionFormData.fromTransaction(Transaction transaction) {
    final category = AppCategories.findById(transaction.categoryId);
    return TransactionFormData(
      id: transaction.id,
      amount: transaction.amount.abs().toString(),
      title: transaction.title,
      notes: transaction.notes,
      type: transaction.type,
      selectedCategory: category,
      date: transaction.date,
      time: transaction.date,
    );
  }

  TransactionFormData copyWith({
    String? id,
    String? amount,
    String? title,
    String? notes,
    TransactionType? type,
    Category? selectedCategory,
    DateTime? date,
    DateTime? time,
    bool clearNotes = false,
    bool clearCategory = false,
  }) {
    return TransactionFormData(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      notes: clearNotes ? null : (notes ?? this.notes),
      type: type ?? this.type,
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }

  // Validation
  Map<TransactionFormError, String> validate() {
    final errors = <TransactionFormError, String>{};

    // Amount validation
    if (amount.trim().isEmpty) {
      errors[TransactionFormError.amountRequired] = TransactionFormError.amountRequired.message;
    } else {
      final amountValue = double.tryParse(amount.replaceAll(',', ''));
      if (amountValue == null || amountValue <= 0) {
        errors[TransactionFormError.amountMustBePositive] = TransactionFormError.amountMustBePositive.message;
      }
    }

    // Title validation
    if (title.trim().isEmpty) {
      errors[TransactionFormError.titleRequired] = TransactionFormError.titleRequired.message;
    } else if (title.length > 100) {
      errors[TransactionFormError.titleTooLong] = TransactionFormError.titleTooLong.message;
    }

    // Category validation
    if (selectedCategory == null) {
      errors[TransactionFormError.categoryRequired] = TransactionFormError.categoryRequired.message;
    }

    // Date validation
    final now = DateTime.now();
    final combinedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (combinedDateTime.isAfter(now)) {
      errors[TransactionFormError.dateInFuture] = TransactionFormError.dateInFuture.message;
    }

    // Notes validation
    if (notes != null && notes!.length > 500) {
      errors[TransactionFormError.notesTooLong] = TransactionFormError.notesTooLong.message;
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;

  // Convert to Transaction entity
  Transaction toTransaction() {
    if (!isValid) {
      throw StateError('Cannot convert invalid form data to transaction');
    }

    final amountValue = double.parse(amount.replaceAll(',', ''));
    final finalAmount = type == TransactionType.expense ? -amountValue.abs() : amountValue.abs();
    
    final combinedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    return Transaction(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title.trim(),
      amount: finalAmount,
      type: type,
      category: selectedCategory!,
      date: combinedDateTime,
      description: notes?.trim().isEmpty == true ? null : notes?.trim(),
      createdAt: DateTime.now(),
    );
  }

  // Computed properties
  double? get amountValue {
    final cleanAmount = amount.replaceAll(',', '');
    return double.tryParse(cleanAmount);
  }

  bool get isEditMode => id != null;

  List<Category> get availableCategories {
    return AppCategories.getCategoriesFor(type == TransactionType.income);
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    title,
    notes,
    type,
    selectedCategory,
    date,
    time,
  ];
}

/// Form submission state
enum FormSubmissionStatus {
  initial,
  inProgress,
  success,
  failure,
}

/// Complete form state
class TransactionFormState extends Equatable {
  final TransactionFormData formData;
  final Map<TransactionFormError, String> errors;
  final FormSubmissionStatus submissionStatus;
  final String? submissionError;

  const TransactionFormState({
    required this.formData,
    this.errors = const {},
    this.submissionStatus = FormSubmissionStatus.initial,
    this.submissionError,
  });

  factory TransactionFormState.initial() {
    return TransactionFormState(
      formData: TransactionFormData.initial(),
    );
  }

  factory TransactionFormState.forEdit(Transaction transaction) {
    return TransactionFormState(
      formData: TransactionFormData.fromTransaction(transaction),
    );
  }

  TransactionFormState copyWith({
    TransactionFormData? formData,
    Map<TransactionFormError, String>? errors,
    FormSubmissionStatus? submissionStatus,
    String? submissionError,
    bool clearSubmissionError = false,
  }) {
    return TransactionFormState(
      formData: formData ?? this.formData,
      errors: errors ?? this.errors,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionError: clearSubmissionError ? null : (submissionError ?? this.submissionError),
    );
  }

  // Convenience methods
  bool get isValid => errors.isEmpty && formData.isValid;
  bool get isSubmitting => submissionStatus == FormSubmissionStatus.inProgress;
  bool get hasSubmissionError => submissionStatus == FormSubmissionStatus.failure;
  bool get isSuccessful => submissionStatus == FormSubmissionStatus.success;

  String? getFieldError(TransactionFormError error) {
    return errors[error];
  }

  @override
  List<Object?> get props => [
    formData,
    errors,
    submissionStatus,
    submissionError,
  ];
}