import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'spacing.dart';

/// Application theme configuration
class AppTheme {
  // Private constructor
  const AppTheme._();

  // Color palette (kept for backward compatibility)
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color errorColor = AppColors.error;
  static const Color successColor = AppColors.success;
  static const Color warningColor = AppColors.warning;
  static const Color backgroundColor = AppColors.background;
  static const Color surfaceColor = AppColors.surface;
  static const Color textPrimaryColor = AppColors.textPrimary;
  static const Color textSecondaryColor = AppColors.textSecondary;

  // Income and Expense colors
  static const Color incomeColor = AppColors.income;
  static const Color expenseColor = AppColors.expense;

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: Spacing.elevation0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: Spacing.elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusM),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.space24,
            vertical: Spacing.space12,
          ),
          elevation: Spacing.elevation2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Spacing.radiusS),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: Spacing.elevation6,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        elevation: Spacing.elevation8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: Spacing.elevation2,
        height: 80,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: 24,
            );
          }
          return const IconThemeData(
            color: AppColors.textSecondary,
            size: 24,
          );
        }),
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusL),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusS),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusS),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusS),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Spacing.radiusS),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.space16,
          vertical: Spacing.space12,
        ),
      ),
      textTheme: TextTheme(
        displayLarge:
            AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium:
            AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
        displaySmall:
            AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
        headlineLarge:
            AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium:
            AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
        headlineSmall:
            AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        titleLarge:
            AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        titleMedium:
            AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
        titleSmall:
            AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium:
            AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall:
            AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        labelLarge:
            AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
        labelMedium:
            AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
        labelSmall:
            AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
