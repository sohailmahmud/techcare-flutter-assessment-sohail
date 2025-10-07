import 'package:get_it/get_it.dart';
import 'data/cache/hive_cache_manager.dart';
import 'data/datasources/mock_dashboard_datasource.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/get_dashboard_summary.dart';
import 'domain/usecases/refresh_dashboard.dart';
import 'presentation/dashboard/bloc/dashboard_bloc.dart';
import 'presentation/transactions/bloc/transactions_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Dashboard
  // Bloc
  sl.registerFactory(
    () => DashboardBloc(
      getDashboardSummary: sl(),
      refreshDashboard: sl(),
    ),
  );

  //! Features - Transactions
  // Bloc
  sl.registerFactory(() => TransactionsBloc(cacheManager: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetDashboardSummary(sl()));
  sl.registerLazySingleton(() => RefreshDashboard(sl()));

  // Repository
  sl.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(dataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<MockDashboardDataSource>(
    () => MockDashboardDataSource(),
  );

  // Cache Manager
  sl.registerLazySingleton<HiveCacheManager>(
    () => HiveCacheManager(),
  );
}