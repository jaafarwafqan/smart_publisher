import 'package:flutter/material.dart';
import 'app_colors.dart';

final class AppTextTheme {
  AppTextTheme._();

  static TextTheme textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor = isDark ? Colors.white70 : AppColors.textSecondary;

    final baseTextTheme = Typography.material2021().black;

    return baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: primaryColor),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: primaryColor),
      titleLarge: baseTextTheme.titleLarge?.copyWith(color: primaryColor),
      titleMedium: baseTextTheme.titleMedium?.copyWith(color: primaryColor),
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: primaryColor),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: primaryColor),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: secondaryColor),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: secondaryColor),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: primaryColor),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: secondaryColor),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: secondaryColor),
    );
  }
}
