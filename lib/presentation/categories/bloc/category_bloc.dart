import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/category.dart';
import '../../../core/utils/logger.dart';
import '../../../core/bloc/event_transformers.dart';
import '../../../domain/repositories/category_repository.dart';

// Events
abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

class SelectCategory extends CategoryEvent {
  final String? categoryId;

  const SelectCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class RefreshCategories extends CategoryEvent {
  const RefreshCategories();
}

class FilterCategoriesByType extends CategoryEvent {
  final bool? isIncome; // null means all categories

  const FilterCategoriesByType(this.isIncome);

  @override
  List<Object?> get props => [isIncome];
}

// States
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {
  const CategoryInitial();
}

class CategoryLoading extends CategoryState {
  const CategoryLoading();
}

class CategoryLoaded extends CategoryState {
  final List<Category> categories;
  final String? selectedCategoryId;

  const CategoryLoaded({
    required this.categories,
    this.selectedCategoryId,
  });

  @override
  List<Object?> get props => [categories, selectedCategoryId];

  CategoryLoaded copyWith({
    List<Category>? categories,
    String? selectedCategoryId,
  }) {
    return CategoryLoaded(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }
}

class CategoryError extends CategoryState {
  final String error;

  const CategoryError(this.error);

  @override
  List<Object> get props => [error];
}

// BLoC Implementation
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository? categoryRepository;

  CategoryBloc({this.categoryRepository}) : super(const CategoryInitial()) {
    // Load categories with sequential processing
    on<LoadCategories>(
      _onLoadCategories,
      transformer: EventTransformers.sequential(),
    );

    // Select category with throttle to prevent excessive selections
    on<SelectCategory>(
      _onSelectCategory,
      transformer:
          EventTransformers.throttle(const Duration(milliseconds: 200)),
    );

    // Refresh with restartable strategy
    on<RefreshCategories>(
      _onRefreshCategories,
      transformer: EventTransformers.restartable(),
    );

    // Filter categories by type with throttle
    on<FilterCategoriesByType>(
      _onFilterCategoriesByType,
      transformer:
          EventTransformers.throttle(const Duration(milliseconds: 300)),
    );
  }

  Future<void> _onLoadCategories(
      LoadCategories event, Emitter<CategoryState> emit) async {
    try {
      emit(const CategoryLoading());
      Logger.d('Loading categories');

      if (categoryRepository != null) {
        // Use repository for API data
        final result = await categoryRepository!.getCategories();

        result.fold(
          (failure) {
            Logger.e('Error loading categories from repository',
                error: failure.message);
            // Fallback to local categories
            _loadCategoriesLocally(emit);
          },
          (categories) {
            emit(CategoryLoaded(categories: categories));
            Logger.i(
                'Categories loaded successfully from repository: ${categories.length} categories');
          },
        );
      } else {
        // Fallback to local categories
        _loadCategoriesLocally(emit);
      }
    } catch (error) {
      Logger.e('Error loading categories', error: error);
      emit(CategoryError('Failed to load categories: $error'));
    }
  }

  void _loadCategoriesLocally(Emitter<CategoryState> emit) async {
    try {
      final categories = await _loadCategories();
      emit(CategoryLoaded(categories: categories));
      Logger.i(
          'Categories loaded successfully from local data: ${categories.length} categories');
    } catch (error) {
      Logger.e('Error loading local categories', error: error);
      emit(CategoryError('Failed to load local categories: $error'));
    }
  }

  Future<void> _onSelectCategory(
      SelectCategory event, Emitter<CategoryState> emit) async {
    try {
      Logger.d('Selecting category: ${event.categoryId}');

      final currentState = state;
      if (currentState is CategoryLoaded) {
        emit(currentState.copyWith(selectedCategoryId: event.categoryId));
        Logger.i('Category selected: ${event.categoryId}');
      } else {
        // If categories aren't loaded yet, load them first
        if (categoryRepository != null) {
          final result = await categoryRepository!.getCategories();
          result.fold(
            (failure) {
              Logger.e('Error loading categories for selection',
                  error: failure.message);
              // Fallback to local categories
              _selectCategoryWithLocalData(event.categoryId, emit);
            },
            (categories) {
              emit(CategoryLoaded(
                categories: categories,
                selectedCategoryId: event.categoryId,
              ));
              Logger.i(
                  'Categories loaded and category selected: ${event.categoryId}');
            },
          );
        } else {
          // Fallback to local categories
          _selectCategoryWithLocalData(event.categoryId, emit);
        }
      }
    } catch (error) {
      Logger.e('Error selecting category', error: error);
      emit(CategoryError('Failed to select category: $error'));
    }
  }

  void _selectCategoryWithLocalData(
      String? categoryId, Emitter<CategoryState> emit) async {
    try {
      final categories = await _loadCategories();
      emit(CategoryLoaded(
        categories: categories,
        selectedCategoryId: categoryId,
      ));
      Logger.i('Local categories loaded and category selected: $categoryId');
    } catch (error) {
      Logger.e('Error selecting category with local data', error: error);
      emit(CategoryError('Failed to select category with local data: $error'));
    }
  }

  Future<void> _onRefreshCategories(
      RefreshCategories event, Emitter<CategoryState> emit) async {
    try {
      Logger.d('Refreshing categories');

      final currentState = state;
      final selectedCategoryId = currentState is CategoryLoaded
          ? currentState.selectedCategoryId
          : null;

      if (categoryRepository != null) {
        // Clear cache and reload from repository
        await categoryRepository!.clearCache();
        final result = await categoryRepository!.getCategories();

        result.fold(
          (failure) {
            Logger.e('Error refreshing categories from repository',
                error: failure.message);
            // Fallback to local refresh
            _refreshCategoriesLocally(selectedCategoryId, emit);
          },
          (categories) {
            emit(CategoryLoaded(
              categories: categories,
              selectedCategoryId: selectedCategoryId,
            ));
            Logger.i('Categories refreshed successfully from repository');
          },
        );
      } else {
        // Fallback to local refresh
        _refreshCategoriesLocally(selectedCategoryId, emit);
      }
    } catch (error) {
      Logger.e('Error refreshing categories', error: error);
      emit(CategoryError('Failed to refresh categories: $error'));
    }
  }

  void _refreshCategoriesLocally(
      String? selectedCategoryId, Emitter<CategoryState> emit) async {
    try {
      final categories = await _loadCategories();

      emit(CategoryLoaded(
        categories: categories,
        selectedCategoryId: selectedCategoryId,
      ));

      Logger.i('Categories refreshed successfully from local data');
    } catch (error) {
      Logger.e('Error refreshing local categories', error: error);
      emit(CategoryError('Failed to refresh local categories: $error'));
    }
  }

  Future<void> _onFilterCategoriesByType(
      FilterCategoriesByType event, Emitter<CategoryState> emit) async {
    try {
      emit(const CategoryLoading());
      Logger.d('Filtering categories by type: ${event.isIncome}');

      final currentState = state;
      final selectedCategoryId = currentState is CategoryLoaded
          ? currentState.selectedCategoryId
          : null;

      if (categoryRepository != null) {
        // Use repository for API data
        final result = event.isIncome != null
            ? await categoryRepository!.getCategoriesByType(event.isIncome!)
            : await categoryRepository!.getCategories();

        result.fold(
          (failure) {
            Logger.e('Error filtering categories from repository',
                error: failure.message);
            // Fallback to local filtering
            _filterCategoriesLocally(event.isIncome, selectedCategoryId, emit);
          },
          (categories) {
            emit(CategoryLoaded(
              categories: categories,
              selectedCategoryId: selectedCategoryId,
            ));
            Logger.i(
                'Categories filtered successfully from repository: ${categories.length} categories');
          },
        );
      } else {
        // Fallback to local filtering
        _filterCategoriesLocally(event.isIncome, selectedCategoryId, emit);
      }
    } catch (error) {
      Logger.e('Error filtering categories', error: error);
      emit(CategoryError('Failed to filter categories: $error'));
    }
  }

  void _filterCategoriesLocally(bool? isIncome, String? selectedCategoryId,
      Emitter<CategoryState> emit) async {
    try {
      final allCategories = await _loadCategories();

      final filteredCategories = isIncome != null
          ? allCategories
              .where((category) => category.isIncome == isIncome)
              .toList()
          : allCategories;

      emit(CategoryLoaded(
        categories: filteredCategories,
        selectedCategoryId: selectedCategoryId,
      ));

      Logger.i(
          'Categories filtered successfully from local data: ${filteredCategories.length} categories');
    } catch (error) {
      Logger.e('Error filtering local categories', error: error);
      emit(CategoryError('Failed to filter local categories: $error'));
    }
  }

  Future<List<Category>> _loadCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Return all available categories (both income and expense)
    final allCategories = <Category>[];
    allCategories.addAll(AppCategories.expenseCategories);
    allCategories.addAll(AppCategories.incomeCategories);

    return allCategories;
  }
}
