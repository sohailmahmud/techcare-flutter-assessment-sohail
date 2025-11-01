import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

// Import the generated Hive registrar
import 'hive_registrar.g.dart';

// Existing imports
import 'core/network/network_client.dart';
import 'data/cache/hive_cache_manager.dart';
import 'data/datasources/mock_api_service.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/get_dashboard_summary.dart';
import 'domain/usecases/refresh_dashboard.dart';
import 'domain/usecases/get_transactions.dart';
import 'domain/usecases/create_transaction.dart';
import 'domain/usecases/update_transaction.dart' as update_usecase;
import 'domain/usecases/delete_transaction.dart' as delete_usecase;
import 'domain/usecases/get_analytics.dart';
import 'presentation/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/transactions/list/bloc/transactions_bloc.dart';
import 'presentation/transactions/form/bloc/transaction_form_bloc.dart';
import 'presentation/analytics/bloc/analytics_bloc.dart';
import 'presentation/categories/bloc/category_bloc.dart';

// New API integration imports
import 'data/datasources/remote_data_source.dart';
import 'data/datasources/local_data_source.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'data/repositories/category_repository_impl.dart';
import 'data/repositories/analytics_repository_impl.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/repositories/category_repository.dart';
import 'domain/repositories/analytics_repository.dart';
import 'core/sync_notification_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Initialize Hive
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);

  // Register all Hive type adapters using the generated registrar
  Hive.registerAdapters();

  //! External dependencies
  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  //! Network Client
  sl.registerLazySingleton<NetworkClient>(() => NetworkClient());

  // Future API service integration (when real API is available)
  // sl.registerLazySingleton<ApiService>(() => ApiService(sl<NetworkClient>()));

  //! Features - Dashboard
  // Bloc
  sl.registerFactory(
    () => DashboardBloc(getDashboardSummary: sl(), refreshDashboard: sl()),
  );

  //! Features - Transactions
  // Use cases
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => CreateTransaction(sl()));
  sl.registerLazySingleton(() => update_usecase.UpdateTransaction(sl()));
  sl.registerLazySingleton(() => delete_usecase.DeleteTransaction(sl()));

  // Bloc
  sl.registerLazySingleton(
    () => TransactionsBloc(
      cacheManager: sl(),
      transactionRepository: sl<TransactionRepository>(),
    ),
  );

  // Attach sync listener to TransactionsBloc to handle id replacements
  // when pending creations are synced and server returns real IDs.
  try {
    final bloc = sl<TransactionsBloc>();
    final syncService = sl<SyncNotificationService>();
    syncService.stream.listen((syncResult) {
      if (syncResult.idMap.isEmpty) return;
      // Dispatch an internal event to the bloc to apply id mappings.
      bloc.add(ApplyIdMap(syncResult.idMap));
    });
  } catch (_) {
    // If DI ordering prevents resolving yet, it's fine - the listener
    // will be attached when both services are available.
  }

  //! Features - Transaction Form
  // Bloc
  sl.registerFactory(
    () => TransactionFormBloc(transactionsBloc: sl<TransactionsBloc>()),
  );

  //! Features - Analytics
  // Use cases
  sl.registerLazySingleton(() => GetAnalytics(sl()));

  // Bloc
  sl.registerFactory(
    () => AnalyticsBloc(transactionsBloc: sl(), categories: []),
  );

  //! Features - Categories
  // Bloc
  sl.registerFactory(() => CategoryBloc());

  //! API Integration - New Repositories
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDataSource: sl<RemoteDataSource>(),
      localDataSource: sl<LocalDataSource>(),
      connectivity: sl<Connectivity>(),
    ),
  );

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      sl<RemoteDataSource>(),
      sl<LocalDataSource>(),
      sl<Connectivity>(),
    ),
  );

  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(
      sl<RemoteDataSource>(),
      sl<LocalDataSource>(),
      sl<Connectivity>(),
    ),
  );

  //! API Integration - Data Sources
  // Register MockApiService (initialization will happen on first use)
  // Allow configuring failure probability via compile-time environment
  // variable `MOCK_API_FAILURE_CHANCE` (value between 0.0 and 1.0). If not
  // provided or invalid, the default of 0.10 is used.
  const double defaultFailureChance = 0.10;
  const String envRaw = String.fromEnvironment(
    'MOCK_API_FAILURE_CHANCE',
    defaultValue: '',
  );
  double failureChance = defaultFailureChance;
  final parsed = double.tryParse(envRaw);
  if (parsed != null && parsed >= 0.0 && parsed <= 1.0) {
    failureChance = parsed;
  }
  sl.registerLazySingleton<MockApiService>(
    () => MockApiService(failureChance: failureChance),
  );

  sl.registerLazySingleton<RemoteDataSource>(
    () => RemoteDataSourceImpl(sl<MockApiService>()),
  );

  // Initialize LocalDataSource after Hive is ready
  final localDataSource = LocalDataSourceImpl();
  await localDataSource.initialize();
  sl.registerLazySingleton<LocalDataSource>(() => localDataSource);

  // Sync notification service - used to surface sync results to the UI
  sl.registerLazySingleton(() => SyncNotificationService());

  // If the sync notification service is present, wire a retry handler that
  // delegates to the TransactionRepository.retryOperations method.
  try {
    sl<SyncNotificationService>().setRetryHandler((failedItems) async {
      final result = await sl<TransactionRepository>().retryOperations(
        failedItems,
      );
      result.fold(
        (failure) {
          // nothing to notify on failure
        },
        (syncResult) {
          try {
            sl<SyncNotificationService>().notify(syncResult);
          } catch (_) {}
        },
      );
      return result;
    });
  } catch (_) {
    // ignore if DI order prevents resolving yet
  }

  // Connectivity -> auto-sync pending offline changes when device becomes online.
  // Use a simple in-flight guard and debounce timer to avoid overlapping syncs.
  // These are kept at module scope so they persist for the app lifetime.
  bool syncInProgress = false;
  Timer? syncDebounce;

  // Also attempt a startup sync if the device is currently online.
  try {
    final current = await sl<Connectivity>().checkConnectivity();
    final isOnlineNow =
        current == ConnectivityResult.wifi ||
        current == ConnectivityResult.mobile;
    if (isOnlineNow) {
      // Schedule a short delayed sync to avoid racing startup tasks
      syncDebounce = Timer(const Duration(milliseconds: 250), () async {
        if (syncInProgress) return;
        syncInProgress = true;
        try {
          final result = await sl<TransactionRepository>().syncOfflineChanges();
          result.fold(
            (failure) {
              // ignore for startup
            },
            (syncResult) {
              try {
                sl<SyncNotificationService>().notify(syncResult);
              } catch (_) {}
            },
          );
        } catch (_) {
        } finally {
          syncInProgress = false;
        }
      });
    }
  } catch (_) {
    // ignore connectivity check errors on startup
  }

  sl<Connectivity>().onConnectivityChanged.listen((result) async {
    // Consider wifi or mobile as "online". Other values (none) are offline.
    final isOnline =
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile;
    if (!isOnline) return;

    // Debounce quick flapping connectivity events
    syncDebounce?.cancel();
    syncDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (syncInProgress) return;
      syncInProgress = true;
      try {
        final result = await sl<TransactionRepository>().syncOfflineChanges();
        // If sync succeeded (even partially), notify the UI through the
        // SyncNotificationService so the app can present a summary.
        result.fold(
          (failure) {
            // On failure, we still notify with an empty SyncResult? Prefer
            // not to surface anything in UI; errors can be observed separately.
          },
          (syncResult) {
            try {
              sl<SyncNotificationService>().notify(syncResult);
            } catch (_) {
              // Ignore notification errors
            }
          },
        );
      } catch (_) {
        // Swallow errors here; sync logic will persist failures to local store.
      } finally {
        syncInProgress = false;
      }
    });
  });

  //! Existing - Use cases
  sl.registerLazySingleton(() => GetDashboardSummary(sl()));
  sl.registerLazySingleton(() => RefreshDashboard(sl()));

  //! Existing - Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(apiService: sl()),
  );

  //! Existing - Cache Manager
  sl.registerLazySingleton<HiveCacheManager>(() => HiveCacheManager());
}
