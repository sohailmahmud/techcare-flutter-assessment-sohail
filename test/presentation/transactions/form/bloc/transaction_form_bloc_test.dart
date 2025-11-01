import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fintrack/presentation/transactions/form/bloc/transaction_form_bloc.dart';
import 'package:fintrack/presentation/transactions/list/bloc/transactions_bloc.dart';
import 'package:fintrack/domain/entities/transaction.dart';

class MockTransactionsBloc extends Mock implements TransactionsBloc {}

void main() {
  group('TransactionFormBloc', () {
    late TransactionFormBloc transactionFormBloc;
    late MockTransactionsBloc mockTransactionsBloc;

    setUp(() {
      mockTransactionsBloc = MockTransactionsBloc();
      transactionFormBloc = TransactionFormBloc(
        transactionsBloc: mockTransactionsBloc,
      );
    });

    tearDown(() {
      transactionFormBloc.close();
    });

    test('initial state is TransactionFormInitial', () {
      expect(transactionFormBloc.state, equals(const TransactionFormInitial()));
    });

    group('InitializeForm', () {
      blocTest<TransactionFormBloc, TransactionFormBlocState>(
        'emits [TransactionFormReady] when form is initialized without transaction',
        build: () => transactionFormBloc,
        act: (bloc) => bloc.add(const InitializeForm()),
        expect: () => [
          isA<TransactionFormReady>().having(
            (state) => state.formData.type,
            'type',
            TransactionType.expense,
          ),
        ],
      );
    });

    group('AmountChanged', () {
      blocTest<TransactionFormBloc, TransactionFormBlocState>(
        'updates amount when valid amount is entered',
        build: () => transactionFormBloc,
        seed: () => const TransactionFormInitial(),
        act: (bloc) => bloc
          ..add(const InitializeForm())
          ..add(const AmountChanged('100')),
        expect: () => [
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>().having(
            (state) => state.formData.amount,
            'amount',
            '100',
          ),
        ],
      );

      blocTest<TransactionFormBloc, TransactionFormBlocState>(
        'handles empty amount',
        build: () => transactionFormBloc,
        seed: () => const TransactionFormInitial(),
        act: (bloc) => bloc
          ..add(const InitializeForm())
          ..add(const AmountChanged('')),
        expect: () => [
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>().having(
            (state) => state.formData.amount,
            'amount',
            '',
          ),
        ],
      );
    });

    group('TitleChanged', () {
      blocTest<TransactionFormBloc, TransactionFormBlocState>(
        'updates title when title is entered',
        build: () => transactionFormBloc,
        seed: () => const TransactionFormInitial(),
        act: (bloc) => bloc
          ..add(const InitializeForm())
          ..add(const TitleChanged('Test Transaction')),
        expect: () => [
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>().having(
            (state) => state.formData.title,
            'title',
            'Test Transaction',
          ),
        ],
      );
    });

    group('TransactionTypeChanged', () {
      blocTest<TransactionFormBloc, TransactionFormBlocState>(
        'updates transaction type',
        build: () => transactionFormBloc,
        seed: () => const TransactionFormInitial(),
        act: (bloc) => bloc
          ..add(const InitializeForm())
          ..add(const TransactionTypeChanged(TransactionType.income)),
        expect: () => [
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>().having(
            (state) => state.formData.type,
            'type',
            TransactionType.income,
          ),
        ],
      );
    });

    group('ValidateForm', () {
      blocTest<TransactionFormBloc, TransactionFormBlocState>(
        'validates form and shows errors for empty required fields',
        build: () => transactionFormBloc,
        seed: () => const TransactionFormInitial(),
        act: (bloc) => bloc
          ..add(const InitializeForm())
          ..add(const ValidateForm()),
        expect: () => [
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>().having(
            (state) => state.errors.isNotEmpty,
            'hasErrors',
            isTrue,
          ),
        ],
      );
    });

    group('ResetForm', () {
      blocTest<TransactionFormBloc, TransactionFormBlocState>(
        'resets form to initial state',
        build: () => transactionFormBloc,
        seed: () => const TransactionFormInitial(),
        act: (bloc) => bloc
          ..add(const InitializeForm())
          ..add(const TitleChanged('Test'))
          ..add(const AmountChanged('100'))
          ..add(const ResetForm()),
        expect: () => [
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>(),
          isA<TransactionFormReady>()
              .having((state) => state.formData.title, 'title', isEmpty)
              .having((state) => state.formData.amount, 'amount', isEmpty),
        ],
      );
    });
  });
}
