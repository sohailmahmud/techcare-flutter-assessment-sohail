import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../../domain/entities/category.dart';
import '../../list/bloc/transactions_bloc.dart';
import '../models/transaction_form_models.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../../core/utils/id_utils.dart';

// Events
abstract class TransactionFormEvent extends Equatable {
  const TransactionFormEvent();

  @override
  List<Object?> get props => [];
}

class InitializeForm extends TransactionFormEvent {
  final Transaction? transaction;

  const InitializeForm({this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class AmountChanged extends TransactionFormEvent {
  final String amount;

  const AmountChanged(this.amount);

  @override
  List<Object> get props => [amount];
}

class TitleChanged extends TransactionFormEvent {
  final String title;

  const TitleChanged(this.title);

  @override
  List<Object> get props => [title];
}

class NotesChanged extends TransactionFormEvent {
  final String notes;

  const NotesChanged(this.notes);

  @override
  List<Object> get props => [notes];
}

class TransactionTypeChanged extends TransactionFormEvent {
  final TransactionType type;

  const TransactionTypeChanged(this.type);

  @override
  List<Object> get props => [type];
}

class CategorySelected extends TransactionFormEvent {
  final Category category;

  const CategorySelected(this.category);

  @override
  List<Object> get props => [category];
}

class DateChanged extends TransactionFormEvent {
  final DateTime date;

  const DateChanged(this.date);

  @override
  List<Object> get props => [date];
}

class TimeChanged extends TransactionFormEvent {
  final DateTime time;

  const TimeChanged(this.time);

  @override
  List<Object> get props => [time];
}

class ValidateForm extends TransactionFormEvent {
  const ValidateForm();
}

class SubmitForm extends TransactionFormEvent {
  const SubmitForm();
}

class ResetForm extends TransactionFormEvent {
  const ResetForm();
}

// States
abstract class TransactionFormBlocState extends Equatable {
  const TransactionFormBlocState();

  @override
  List<Object?> get props => [];
}

class TransactionFormInitial extends TransactionFormBlocState {
  const TransactionFormInitial();
}

class TransactionFormReady extends TransactionFormBlocState {
  final TransactionFormData formData;
  final Map<TransactionFormError, String> errors;
  final FormSubmissionStatus submissionStatus;
  final String? submissionError;

  const TransactionFormReady({
    required this.formData,
    this.errors = const {},
    this.submissionStatus = FormSubmissionStatus.initial,
    this.submissionError,
  });

  TransactionFormReady copyWith({
    TransactionFormData? formData,
    Map<TransactionFormError, String>? errors,
    FormSubmissionStatus? submissionStatus,
    String? submissionError,
    bool clearSubmissionError = false,
  }) {
    return TransactionFormReady(
      formData: formData ?? this.formData,
      errors: errors ?? this.errors,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      submissionError: clearSubmissionError
          ? null
          : (submissionError ?? this.submissionError),
    );
  }

  // Convenience getters
  bool get isValid => errors.isEmpty && formData.isValid;
  bool get isSubmitting => submissionStatus == FormSubmissionStatus.inProgress;
  bool get hasSubmissionError =>
      submissionStatus == FormSubmissionStatus.failure;
  bool get isSuccessful => submissionStatus == FormSubmissionStatus.success;
  bool get isEditMode => formData.isEditMode;

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

// BLoC Implementation
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormBlocState> {
  final TransactionsBloc _transactionsBloc;

  TransactionFormBloc({required TransactionsBloc transactionsBloc})
    : _transactionsBloc = transactionsBloc,
      super(const TransactionFormInitial()) {
    on<InitializeForm>(_onInitializeForm);
    on<AmountChanged>(_onAmountChanged);
    on<TitleChanged>(_onTitleChanged);
    on<NotesChanged>(_onNotesChanged);
    on<TransactionTypeChanged>(_onTransactionTypeChanged);
    on<CategorySelected>(_onCategorySelected);
    on<DateChanged>(_onDateChanged);
    on<TimeChanged>(_onTimeChanged);
    on<ValidateForm>(_onValidateForm);
    on<SubmitForm>(_onSubmitForm);
    on<ResetForm>(_onResetForm);
  }

  Future<void> _onInitializeForm(
    InitializeForm event,
    Emitter<TransactionFormBlocState> emit,
  ) async {
    final formData = event.transaction != null
        ? await TransactionFormData.fromTransaction(event.transaction!)
        : TransactionFormData.initial();

    emit(TransactionFormReady(formData: formData));
  }

  void _onAmountChanged(
    AmountChanged event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final formattedAmount = _formatAmount(event.amount);
    final updatedFormData = currentState.formData.copyWith(
      amount: formattedAmount,
    );
    final errors = _validateField(
      updatedFormData,
      TransactionFormError.amountRequired,
      currentState.errors,
    );

    emit(
      currentState.copyWith(
        formData: updatedFormData,
        errors: errors,
        submissionStatus: FormSubmissionStatus.initial,
        clearSubmissionError: true,
      ),
    );
  }

  void _onTitleChanged(
    TitleChanged event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final updatedFormData = currentState.formData.copyWith(title: event.title);
    final errors = _validateField(
      updatedFormData,
      TransactionFormError.titleRequired,
      currentState.errors,
    );

    emit(
      currentState.copyWith(
        formData: updatedFormData,
        errors: errors,
        submissionStatus: FormSubmissionStatus.initial,
        clearSubmissionError: true,
      ),
    );
  }

  void _onNotesChanged(
    NotesChanged event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final updatedFormData = currentState.formData.copyWith(notes: event.notes);
    final errors = _validateField(
      updatedFormData,
      TransactionFormError.notesTooLong,
      currentState.errors,
    );

    emit(
      currentState.copyWith(
        formData: updatedFormData,
        errors: errors,
        submissionStatus: FormSubmissionStatus.initial,
        clearSubmissionError: true,
      ),
    );
  }

  void _onTransactionTypeChanged(
    TransactionTypeChanged event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final updatedFormData = currentState.formData.copyWith(
      type: event.type,
      clearCategory: true,
    );

    emit(
      currentState.copyWith(
        formData: updatedFormData,
        submissionStatus: FormSubmissionStatus.initial,
        clearSubmissionError: true,
      ),
    );
  }

  void _onCategorySelected(
    CategorySelected event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final updatedFormData = currentState.formData.copyWith(
      selectedCategory: event.category,
    );
    final errors = _validateField(
      updatedFormData,
      TransactionFormError.categoryRequired,
      currentState.errors,
    );

    emit(
      currentState.copyWith(
        formData: updatedFormData,
        errors: errors,
        submissionStatus: FormSubmissionStatus.initial,
        clearSubmissionError: true,
      ),
    );
  }

  void _onDateChanged(
    DateChanged event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final updatedFormData = currentState.formData.copyWith(date: event.date);
    final errors = _validateField(
      updatedFormData,
      TransactionFormError.dateInFuture,
      currentState.errors,
    );

    emit(
      currentState.copyWith(
        formData: updatedFormData,
        errors: errors,
        submissionStatus: FormSubmissionStatus.initial,
        clearSubmissionError: true,
      ),
    );
  }

  void _onTimeChanged(
    TimeChanged event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final updatedFormData = currentState.formData.copyWith(time: event.time);
    final errors = _validateField(
      updatedFormData,
      TransactionFormError.dateInFuture,
      currentState.errors,
    );

    emit(
      currentState.copyWith(
        formData: updatedFormData,
        errors: errors,
        submissionStatus: FormSubmissionStatus.initial,
        clearSubmissionError: true,
      ),
    );
  }

  void _onValidateForm(
    ValidateForm event,
    Emitter<TransactionFormBlocState> emit,
  ) {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final errors = currentState.formData.validate();

    emit(currentState.copyWith(errors: errors));
  }

  Future<void> _onSubmitForm(
    SubmitForm event,
    Emitter<TransactionFormBlocState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TransactionFormReady) return;

    final errors = currentState.formData.validate();
    if (errors.isNotEmpty) {
      emit(currentState.copyWith(errors: errors));
      return;
    }

    emit(
      currentState.copyWith(submissionStatus: FormSubmissionStatus.inProgress),
    );

    try {
      var transaction = currentState.formData.toTransaction();

      // Ensure a stable temporary id exists for optimistic UI and caching.
      if (transaction.id.isEmpty) {
        final tempId = generateTempId();
        transaction = transaction.copyWith(id: tempId);
      }

      // Centralized persistence: call repository to create (this will cache
      // optimistically and/or queue for sync as needed). Only dispatch the
      // AddTransaction event after repository call succeeds to avoid double writes.
      final repo = serviceLocator<TransactionRepository>();
      final result = await repo.createTransaction(transaction);

      result.fold(
        (failure) {
          emit(
            currentState.copyWith(
              submissionStatus: FormSubmissionStatus.failure,
              submissionError: failure.message,
            ),
          );
        },
        (createdTransaction) {
          emit(
            currentState.copyWith(
              submissionStatus: FormSubmissionStatus.success,
            ),
          );

          if (currentState.isEditMode) {
            _transactionsBloc.add(
              UpdateTransaction(
                id: createdTransaction.id,
                transaction: createdTransaction,
              ),
            );
          } else {
            _transactionsBloc.add(AddTransaction(createdTransaction));
          }
        },
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          submissionStatus: FormSubmissionStatus.failure,
          submissionError: e.toString(),
        ),
      );
    }
  }

  // temp id generator moved to `lib/core/utils/id_utils.dart`

  void _onResetForm(ResetForm event, Emitter<TransactionFormBlocState> emit) {
    emit(TransactionFormReady(formData: TransactionFormData.initial()));
  }

  // Helper methods
  String _formatAmount(String amount) {
    String cleanAmount = amount.replaceAll(RegExp(r'[^\d.]'), '');

    final parts = cleanAmount.split('.');
    if (parts.length > 2) {
      cleanAmount = '${parts[0]}.${parts.sublist(1).join('')}';
    }

    final value = double.tryParse(cleanAmount);
    if (value == null) return cleanAmount;

    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final integerPart = value.truncate().toString();
    final formattedInteger = integerPart.replaceAllMapped(
      formatter,
      (Match m) => '${m[1]},',
    );

    if (cleanAmount.contains('.')) {
      final decimalPart = cleanAmount.split('.')[1];
      return '$formattedInteger.$decimalPart';
    } else {
      return formattedInteger;
    }
  }

  Map<TransactionFormError, String> _validateField(
    TransactionFormData formData,
    TransactionFormError field,
    Map<TransactionFormError, String> currentErrors,
  ) {
    final allErrors = formData.validate();
    final errors = Map<TransactionFormError, String>.from(currentErrors);

    if (allErrors.containsKey(field)) {
      errors[field] = allErrors[field]!;
    } else {
      errors.remove(field);
    }

    return errors;
  }
}

// Add Transaction Event (if not already defined in TransactionsBloc)
