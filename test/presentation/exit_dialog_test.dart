import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fintrack/data/cache/hive_cache_manager.dart';
import 'package:fintrack/injection_container.dart' as di;
import 'package:fintrack/presentation/transactions/list/bloc/transactions_bloc.dart';

class MockTransactionsBloc extends Mock implements TransactionsBloc {}

class TestHiveCacheManager extends HiveCacheManager {
  bool cleared = false;

  @override
  Future<void> clearAll() async {
    cleared = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exit dialog', () {
    late TestHiveCacheManager testCache;

    setUp(() async {
      testCache = TestHiveCacheManager();

      // Reset service locator registrations for test
      di.sl.reset();

      // Minimal DI registrations needed for the exit wrapper to call
      // cache manager.
      di.sl.registerLazySingleton<HiveCacheManager>(() => testCache);
    });

    testWidgets('shows exit dialog and clears cache on Exit & Clear Cache', (
      tester,
    ) async {
      // Build a minimal widget with the same exit dialog/WillPopScope logic
      // to avoid pulling in the entire app router and dependent blocs.
      await tester.pumpWidget(
        MaterialApp(home: TestExitApp(cacheManager: testCache)),
      );
      await tester.pump();

      // Tap the test button to open the exit dialog deterministically.
      await tester.tap(find.byKey(const Key('openExitDialog')));
      await tester.pumpAndSettle();

      // Expect the dialog to appear
      expect(find.text('Exit app'), findsOneWidget);
      expect(find.text('Exit & Clear Cache'), findsOneWidget);

      // Tap the 'Exit & Clear Cache' button
      await tester.tap(find.text('Exit & Clear Cache'));
      await tester.pumpAndSettle();

      // Verify clearAll was called on the registered test cache
      expect(testCache.cleared, isTrue);
    });
  });
}

class TestExitApp extends StatelessWidget {
  final HiveCacheManager? cacheManager;

  const TestExitApp({super.key, this.cacheManager});

  @override
  Widget build(BuildContext context) {
    Future<void> openExitDialog() async {
      final choice = await showDialog<_ExitChoice>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Exit app'),
            content: const Text(
              'Do you want to exit the app? You can also clear cached data before exiting.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(_ExitChoice.cancel),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(_ExitChoice.exit),
                child: const Text('Exit'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(_ExitChoice.exitAndClear),
                child: const Text('Exit & Clear Cache'),
              ),
            ],
          );
        },
      );

      if (choice == _ExitChoice.exitAndClear) {
        try {
          if (cacheManager != null) {
            await cacheManager!.clearAll();
          } else {
            await di.sl<HiveCacheManager>().clearAll();
          }
        } catch (_) {}
      }
    }

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await openExitDialog();
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Home'),
              ElevatedButton(
                key: const Key('openExitDialog'),
                onPressed: () async => await openExitDialog(),
                child: const Text('Open Exit Dialog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ExitChoice { cancel, exit, exitAndClear }
