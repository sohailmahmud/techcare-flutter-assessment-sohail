import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/category.dart';

/// Repository interface for category data
abstract class CategoryRepository {
  /// Get all available categories
  Future<Either<Failure, List<Category>>> getCategories();

  /// Get a single category by ID
  Future<Either<Failure, Category>> getCategory(String id);

  /// Get categories filtered by type (income/expense)
  Future<Either<Failure, List<Category>>> getCategoriesByType(bool isIncome);

  /// Get cached categories (for offline support)
  Future<Either<Failure, List<Category>>> getCachedCategories();

  /// Clear category cache
  Future<Either<Failure, void>> clearCache();
}
