import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:fintrack/presentation/transactions/list/bloc/transactions_bloc.dart';
import 'package:fintrack/domain/entities/transaction.dart' as tx;
import 'package:fintrack/domain/entities/category.dart' as cat;
import 'package:fintrack/domain/repositories/transaction_repository.dart';
import 'package:fintrack/data/cache/hive_cache_manager.dart';

class MockRepo extends Mock implements TransactionRepository {}
class MockCache extends Mock implements HiveCacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransactionsBloc optimistic add and id map', () {
    setUpAll(() {
      registerFallbackValue(const TransactionQuery());
    });
    late MockRepo mockRepo;
    late MockCache mockCache;
    late TransactionsBloc bloc;

    setUp(() {
      mockRepo = MockRepo();
      mockCache = MockCache();
      // Stub repository to return empty response for initial load
    when(() => mockRepo.getTransactions(any(), cancelToken: any(named: 'cancelToken')))
      .thenAnswer((_) async => const Right(PaginatedResponse<tx.Transaction>(data: [], meta: PaginationMeta(currentPage: 1, totalPages: 1, totalItems: 0, itemsPerPage: 20, hasMore: false))));

      bloc = TransactionsBloc(cacheManager: mockCache, transactionRepository: mockRepo);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('adds optimistic transaction and replaces temp id with server id without duplicates', () async {
      const category = cat.Category(id: 'c1', name: 'Cat', icon: Icons.category, color: Colors.grey);
      final tempTx = tx.Transaction(
        id: 'temp_1',
        title: 'Temp',
        amount: 1.0,
        type: tx.TransactionType.expense,
        category: category,
        date: DateTime.now(),
      );

  // Listen to emitted states
      final states = <TransactionsState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(AddTransaction(tempTx));

      // Wait until a TransactionLoaded with the temp id appears (timeout after 1s)
      TransactionLoaded? loadedState;
      final end = DateTime.now().add(const Duration(seconds: 1));
      while (DateTime.now().isBefore(end)) {
        try {
          loadedState = states.lastWhere((s) => s is TransactionLoaded) as TransactionLoaded;
          if (loadedState.transactions.any((t) => t.id == 'temp_1')) break;
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 20));
      }
      expect(loadedState, isNotNull);
      expect(loadedState!.transactions.any((t) => t.id == 'temp_1'), isTrue);

      // Apply id map coming from sync
      bloc.add(const ApplyIdMap({'temp_1': 'srv_1'}));
      await Future.delayed(const Duration(milliseconds: 50));

      final finalLoaded = states.lastWhere((s) => s is TransactionLoaded) as TransactionLoaded;
      expect(finalLoaded.transactions.where((t) => t.id == 'srv_1').length, equals(1));
      expect(finalLoaded.transactions.any((t) => t.id == 'temp_1'), isFalse);

      await sub.cancel();
    });
  });
}
