import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_elevation.dart';
import 'app_radius.dart';

final class AppCardTheme {
  AppCardTheme._();

  static CardThemeData theme({required ColorScheme colorScheme}) {
    final isDark = colorScheme.brightness == Brightness.dark;

    return CardThemeData(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      elevation: isDark ? AppElevation.level0 : AppElevation.level2,
      shadowColor: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
      ).shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: isDark
            ? const BorderSide(color: AppColors.brandSecondary)
            : BorderSide.none,
      ),
      margin: EdgeInsets.zero,
    );
  }
}
