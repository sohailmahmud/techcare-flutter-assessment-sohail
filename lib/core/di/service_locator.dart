import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Data layer
import '../../data/datasources/mock_api_service.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../data/datasources/local_data_source.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/cache/hive_cache_manager.dart';

// Domain layer
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/dashboard_repository.dart';

// Use cases
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../domain/usecases/refresh_dashboard.dart';

// Presentation layer (BLoCs)
import '../../presentation/transactions/list/bloc/transactions_bloc.dart';
import '../../presentation/categories/bloc/category_bloc.dart';
import '../../presentation/analytics/bloc/analytics_bloc.dart';
import '../../presentation/dashboard/bloc/dashboard_bloc.dart';

final GetIt serviceLocator = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // External dependencies
  serviceLocator.registerLazySingleton<Connectivity>(() => Connectivity());

  // Data sources
  serviceLocator.registerLazySingleton<MockApiService>(() => MockApiService());

  // MockDashboardDataSource removed - functionality consolidated into MockApiService

  serviceLocator.registerLazySingleton<RemoteDataSource>(
    () => RemoteDataSourceImpl(serviceLocator<MockApiService>()),
  );

  serviceLocator.registerLazySingleton<LocalDataSource>(
    () => LocalDataSourceImpl(),
  );

  // Cache Manager
  serviceLocator.registerLazySingleton<HiveCacheManager>(
    () => HiveCacheManager(),
  );

  // Repositories
  serviceLocator.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDataSource: serviceLocator<RemoteDataSource>(),
      localDataSource: serviceLocator<LocalDataSource>(),
      connectivity: serviceLocator<Connectivity>(),
    ),
  );

  serviceLocator.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(
      serviceLocator<RemoteDataSource>(),
      serviceLocator<LocalDataSource>(),
      serviceLocator<Connectivity>(),
    ),
  );

  serviceLocator.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(
      serviceLocator<RemoteDataSource>(),
      serviceLocator<LocalDataSource>(),
      serviceLocator<Connectivity>(),
    ),
  );

  serviceLocator.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(apiService: serviceLocator<MockApiService>()),
  );

  // Use cases
  serviceLocator.registerLazySingleton<GetDashboardSummary>(
    () => GetDashboardSummary(serviceLocator<DashboardRepository>()),
  );

  serviceLocator.registerLazySingleton<RefreshDashboard>(
    () => RefreshDashboard(serviceLocator<DashboardRepository>()),
  );

  // BLoCs (Factory registration for fresh instances)
  serviceLocator.registerFactory<TransactionsBloc>(
    () => TransactionsBloc(
      cacheManager: serviceLocator<HiveCacheManager>(),
      transactionRepository: serviceLocator<TransactionRepository>(),
    ),
  );

  serviceLocator.registerFactory<CategoryBloc>(
    () =>
        CategoryBloc(categoryRepository: serviceLocator<CategoryRepository>()),
  );

  serviceLocator.registerFactory<AnalyticsBloc>(
    () => AnalyticsBloc(
      transactionsBloc: serviceLocator<TransactionsBloc>(),
      categories: [],
    ),
  );

  serviceLocator.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      getDashboardSummary: serviceLocator<GetDashboardSummary>(),
      refreshDashboard: serviceLocator<RefreshDashboard>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await serviceLocator.reset();
}

/// Register test dependencies (useful for testing)
Future<void> initializeTestDependencies() async {
  // This would be used for testing with mock implementations
  // Example:
  // serviceLocator.registerLazySingleton<TransactionRepository>(
  //   () => MockTransactionRepository(),
  // );
}
