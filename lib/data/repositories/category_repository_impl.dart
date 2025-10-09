import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/remote_data_source.dart';
import '../datasources/local_data_source.dart';
import '../models/category_model.dart';

/// Implementation of CategoryRepository
class CategoryRepositoryImpl implements CategoryRepository {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource _localDataSource;
  final Connectivity _connectivity;

  CategoryRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivity,
  );

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      if (isOnline) {
        try {
          // Try to fetch from remote
          final remoteCategories = await _remoteDataSource.getCategories();

          // Cache the response by converting to CategoryModels
          final categoryModels = remoteCategories
              .map((category) => CategoryModel.fromEntity(category))
              .toList();
          await _localDataSource.cacheCategories(categoryModels);

          return Right(remoteCategories);
        } on ServerException catch (e) {
          // If remote fails, try cache
          final cachedCategories = await _localDataSource.getCachedCategories();
          if (cachedCategories != null && cachedCategories.isNotEmpty) {
            return Right(cachedCategories
                .whereType<CategoryModel>()
                .map((model) => model.toEntity())
                .toList());
          }
          return Left(ServerFailure(e.toString()));
        }
      } else {
        // Offline - try cache first
        final cachedCategories = await _localDataSource.getCachedCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          return Right(cachedCategories
              .whereType<CategoryModel>()
              .map((model) => model.toEntity())
              .toList());
        }
        return const Left(NetworkFailure(
            'No internet connection and no cached categories available'));
      }
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategory(String id) async {
    try {
      final categoriesResult = await getCategories();

      return categoriesResult.fold(
        (failure) => Left(failure),
        (categories) {
          try {
            final category = categories.firstWhere((cat) => cat.id == id);
            return Right(category);
          } catch (e) {
            return const Left(NotFoundFailure('Category not found'));
          }
        },
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCategoriesByType(
      bool isIncome) async {
    try {
      final categoriesResult = await getCategories();

      return categoriesResult.fold(
        (failure) => Left(failure),
        (categories) {
          final filteredCategories =
              categories.where((cat) => cat.isIncome == isIncome).toList();
          return Right(filteredCategories);
        },
      );
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Category>>> getCachedCategories() async {
    try {
      final cachedCategories = await _localDataSource.getCachedCategories();
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        return Right(cachedCategories
            .whereType<CategoryModel>()
            .map((model) => model.toEntity())
            .toList());
      }
      return const Right([]);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearCache() async {
    try {
      await _localDataSource.clearCategoryCache();
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
