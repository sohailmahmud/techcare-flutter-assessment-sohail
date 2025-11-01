import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/hive_registrar.g.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:fintrack/data/cache/hive_cache_manager.dart';
import 'package:fintrack/domain/entities/transaction.dart';
import 'package:fintrack/domain/entities/category.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HiveCacheManager TTL and expiry', () {
    late HiveCacheManager manager;

    late Directory tmpDir;
    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('fintrack_test_');
      Hive.init(tmpDir.path);
      // Register generated adapters for tests
      Hive.registerAdapters();
      // No platform channel stubs here; using Hive.init with temp dir avoids path_provider.
      manager = HiveCacheManager();
      await manager.initialize();
      await manager.clearAll();
    });

    tearDown(() async {
      await manager.dispose();
      try {
        await tmpDir.delete(recursive: true);
      } catch (_) {}
    });

    test('cached transactions expire after TTL', () async {
      const category = Category(
        id: 'c1',
        name: 'Cat',
        icon: Icons.category,
        color: Colors.grey,
      );
      final tx = Transaction(
        id: 't1',
        title: 'Test',
        amount: 10.0,
        type: TransactionType.expense,
        category: category,
        date: DateTime.now(),
      );

      // Cache with short TTL
      await manager.cacheTransactions([
        tx,
      ], ttl: const Duration(milliseconds: 100));

      // Immediately available
      final first = await manager.getCachedTransactions();
      expect(first.length, greaterThanOrEqualTo(1));

      // Wait for TTL to pass
      await Future.delayed(const Duration(milliseconds: 200));

      final after = await manager.getCachedTransactions();
      expect(after.length, equals(0));
    });
  });
}
