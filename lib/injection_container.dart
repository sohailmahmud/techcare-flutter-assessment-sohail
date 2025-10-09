import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

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
    () => DashboardBloc(
      getDashboardSummary: sl(),
      refreshDashboard: sl(),
    ),
  );

  //! Features - Transactions
  // Use cases
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => CreateTransaction(sl()));
  sl.registerLazySingleton(() => update_usecase.UpdateTransaction(sl()));
  sl.registerLazySingleton(() => delete_usecase.DeleteTransaction(sl()));

  // Bloc
  sl.registerLazySingleton(() => TransactionsBloc(
        cacheManager: sl(),
        transactionRepository: sl<TransactionRepository>(),
      ));

  //! Features - Transaction Form
  // Bloc
  sl.registerFactory(
      () => TransactionFormBloc(transactionsBloc: sl<TransactionsBloc>()));

  //! Features - Analytics
  // Use cases
  sl.registerLazySingleton(() => GetAnalytics(sl()));

  // Bloc
  sl.registerFactory(() => AnalyticsBloc(transactionsBloc: sl()));

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
  sl.registerLazySingleton<MockApiService>(() => MockApiService());

  sl.registerLazySingleton<RemoteDataSource>(
    () => RemoteDataSourceImpl(sl<MockApiService>()),
  );

  // Initialize LocalDataSource after Hive is ready
  final localDataSource = LocalDataSourceImpl();
  await localDataSource.initialize();
  sl.registerLazySingleton<LocalDataSource>(() => localDataSource);

  //! Existing - Use cases
  sl.registerLazySingleton(() => GetDashboardSummary(sl()));
  sl.registerLazySingleton(() => RefreshDashboard(sl()));

  //! Existing - Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(
      apiService: sl(),
    ),
  );

  //! Existing - Cache Manager
  sl.registerLazySingleton<HiveCacheManager>(
    () => HiveCacheManager(),
  );
}
