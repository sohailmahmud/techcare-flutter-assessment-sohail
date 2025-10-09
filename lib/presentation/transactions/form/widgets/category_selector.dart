import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../domain/entities/category.dart';

/// Horizontal scrollable category selector with chips
class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category> onCategorySelected;
  final String? errorText;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories Grid
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Spacing.radiusL),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.border,
              width: hasError ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (hasError)
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Category',
                  style: AppTypography.titleMedium.copyWith(
                    color: hasError ? AppColors.error : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Spacing.space12),
                _buildCategoryGrid(),
              ],
            ),
          ),
        ),

        // Error Message
        if (hasError) ...[
          const SizedBox(height: Spacing.space8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: Spacing.space4),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory?.id == category.id;

          return Padding(
            padding: EdgeInsets.only(
              right: index < categories.length - 1 ? Spacing.space12 : 0,
            ),
            child: GestureDetector(
              onTap: () => onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 100,
                decoration: BoxDecoration(
                  color: isSelected
                      ? category.color.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(Spacing.radiusM),
                  border: Border.all(
                    color: isSelected
                        ? category.color
                        : AppColors.border.withValues(alpha: 0.5),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: category.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category.color
                            : category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(Spacing.radiusS),
                      ),
                      child: Icon(
                        category.icon,
                        color: isSelected ? Colors.white : category.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: Spacing.space8),
                    Text(
                      category.name,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected
                            ? category.color
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Legacy horizontal scrollable category selector (alternative implementation)
class HorizontalCategorySelector extends StatelessWidget {
  final List<Category> categories;
  final Category? selectedCategory;
  final ValueChanged<Category> onCategorySelected;
  final String? errorText;

  const HorizontalCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(Spacing.radiusL),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.border,
              width: hasError ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.space16),
                child: Text(
                  'Select Category',
                  style: AppTypography.titleMedium.copyWith(
                    color: hasError ? AppColors.error : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Spacing.space16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedCategory?.id == category.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: Spacing.space12),
                      child: GestureDetector(
                        onTap: () => onCategorySelected(category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? category.color.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(Spacing.radiusM),
                            border: Border.all(
                              color: isSelected
                                  ? category.color
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? category.color
                                      : category.color.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(Spacing.radiusS),
                                ),
                                child: Icon(
                                  category.icon,
                                  color: isSelected
                                      ? Colors.white
                                      : category.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: Spacing.space4),
                              Text(
                                category.name,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isSelected
                                      ? category.color
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Error Message
        if (hasError) ...[
          const SizedBox(height: Spacing.space8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: Spacing.space4),
              Expanded(
                child: Text(
                  errorText!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
