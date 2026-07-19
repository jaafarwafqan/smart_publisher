import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

final class AppInputTheme {
  AppInputTheme._();

  static InputDecorationTheme theme({required ColorScheme colorScheme}) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.brandSecondary : AppColors.border;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: borderColor),
    );

    final labelColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final hintColor = isDark
        ? Colors.white38
        : AppColors.textSecondary.withValues(alpha: 0.5);
    final helperColor = isDark ? Colors.white54 : AppColors.textSecondary;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: TextStyle(color: AppColors.brandPrimary),
      labelStyle: TextStyle(color: labelColor),
      hintStyle: TextStyle(color: hintColor),
      errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
      helperStyle: TextStyle(color: helperColor, fontSize: 12),
      prefixIconColor: isDark ? Colors.white70 : AppColors.textSecondary,
      suffixIconColor: isDark ? Colors.white70 : AppColors.textSecondary,
    );
  }
}
