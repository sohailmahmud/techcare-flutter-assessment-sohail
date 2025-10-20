
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/hive_registrar.g.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fintrack/domain/repositories/transaction_repository.dart';
import 'package:fintrack/data/datasources/local_data_source.dart';
import 'package:fintrack/data/models/transaction_model.dart';
import 'package:fintrack/data/datasources/remote_data_source.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/domain/entities/category.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalDataSource replaceTempIds', () {
    late LocalDataSourceImpl local;

    late Directory tmpDir;
    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('fintrack_local_ds_');
  Hive.init(tmpDir.path);
  Hive.registerAdapters();
      local = LocalDataSourceImpl();
      await local.initialize();
      await local.clearAllCache();
    });

    tearDown(() async {
      await local.clearAllCache();
      try {
        await tmpDir.delete(recursive: true);
      } catch (_) {}
    });

    test('replaces temp id in individual cache and list caches', () async {
      const category = Category(id: 'c1', name: 'Cat', icon: Icons.category, color: Colors.grey);
      final tx = Transaction(
        id: 'temp_123',
        title: 'Temp Tx',
        amount: 5.0,
        type: TransactionType.expense,
        category: category,
        date: DateTime.now(),
      );

  final txModel = TransactionModel.fromEntity(tx);
  // cache single transaction
  await local.cacheTransaction(txModel);

      // verify cached individually
      final cached = await local.getCachedTransaction('temp_123');
      expect(cached, isNotNull);

      // Simulate list cache using API available on LocalDataSource
      const query = TransactionQuery(page: 1, limit: 20);
      final paginated = PaginatedTransactionsResponse(
        data: [txModel],
        meta: const PaginationMeta(currentPage: 1, totalPages: 1, totalItems: 1, itemsPerPage: 20, hasMore: false),
      );
      await local.cacheTransactions(query, paginated);

      // Replace temp id
      await local.replaceTempIds({'temp_123': 'srv_999'});

      final cachedAfter = await local.getCachedTransaction('srv_999');
      expect(cachedAfter, isNotNull);

  final listCached = await local.getCachedTransactions(const TransactionQuery(page: 1, limit: 20));
  expect(listCached, isNotNull);
  expect(listCached?.data.any((d) => d.id == 'srv_999'), isTrue);
    });
  });
}
