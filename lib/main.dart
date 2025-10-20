import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/router/app_router.dart';
import 'injection_container.dart' as di;
import 'core/sync_notification_service.dart';
import 'presentation/transactions/list/bloc/transactions_bloc.dart';
import 'core/widgets/offline_indicator.dart';
import 'package:flutter/services.dart';
import 'data/cache/hive_cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await di.init();

  // Set up BLoC observer for debugging and monitoring
  Bloc.observer = AppBlocObserver();

  runApp(const FinTrackApp());
}

/// Root widget of the FinTrack application
/// Configures the MaterialApp with go_router for navigation
class FinTrackApp extends StatefulWidget {
  const FinTrackApp({super.key});

  @override
  State<FinTrackApp> createState() => _FinTrackAppState();
}

class _FinTrackAppState extends State<FinTrackApp>
    with WidgetsBindingObserver {
  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register the key with SyncNotificationService if available.
    try {
      di.sl<SyncNotificationService>().setScaffoldMessengerKey(scaffoldMessengerKey);
    } catch (_) {
      // If the service isn't available yet, ignore.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Attempt to dispose cache manager resources when the app widget is
    // disposed. This is best-effort; DI may have a longer lifetime in tests.
    try {
      di.sl<HiveCacheManager>().dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // On pause (background) we softly invalidate the cache so sensitive or
    // stale data isn't shown when the app resumes. On detach (app close), we
    // clear all cache to free disk and ensure a fresh state next launch.
    try {
      final cacheManager = di.sl<HiveCacheManager>();
      if (state == AppLifecycleState.paused) {
        // Soft invalidation marks entries expired but keeps pending ops.
        cacheManager.invalidateCache(invalidateAll: true, type: CacheInvalidationType.soft);
      } else if (state == AppLifecycleState.detached) {
        // Hard clear on app termination
        cacheManager.clearAll();
      }
    } catch (_) {
      // Swallow errors: cache manager might not be registered in some test flows.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<TransactionsBloc>(),
      child: MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: 'Personal Finance Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Wrap app content to intercept back button at root and offer
          // an exit dialog that allows clearing cache.
          return ConnectivityBanner(
            child: Builder(builder: (context) {
              return PopScope<void>(
                onPopInvokedWithResult: (didPop, result) async {
                  if (!didPop) {
                    await _onWillPop(context);
                  }
                },
                child: child!,
              );
            }),
          );
        },
      ),
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    // If navigator can pop, let it pop normally.
    if (Navigator.of(context).canPop()) return true;

    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Exit app'),
          content: const Text('Do you want to exit the app? You can also clear cached data before exiting.'),
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
              onPressed: () => Navigator.of(ctx).pop(_ExitChoice.exitAndClear),
              child: const Text('Exit & Clear Cache'),
            ),
          ],
        );
      },
    );

    if (choice == null || choice == _ExitChoice.cancel) return false;

    try {
      if (choice == _ExitChoice.exitAndClear) {
        await di.sl<HiveCacheManager>().clearAll();
      }
    } catch (_) {}

    // Pop the app (Android) or exit gracefully.
    try {
      SystemNavigator.pop();
    } catch (_) {}

    return false;
  }
}

enum _ExitChoice { cancel, exit, exitAndClear }
