import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

final class AppButtonTheme {
  AppButtonTheme._();

  static final _shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  );

  static const _defaultPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.lg,
  );

  static ButtonStyle _baseStyle({
    required Color foregroundColor,
    EdgeInsetsGeometry? padding,
    OutlinedBorder? shape,
  }) {
    return ButtonStyle(
      padding: WidgetStateProperty.all(padding ?? _defaultPadding),
      shape: WidgetStateProperty.all(shape ?? _shape),
      foregroundColor: WidgetStateProperty.all(foregroundColor),
    );
  }

  static ElevatedButtonThemeData elevatedButtonTheme({
    required ColorScheme colorScheme,
  }) {
    return ElevatedButtonThemeData(
      style: _baseStyle(foregroundColor: Colors.white).copyWith(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(AppColors.brandPrimary),
      ),
    );
  }

  static FilledButtonThemeData filledButtonTheme({
    required ColorScheme colorScheme,
  }) {
    return FilledButtonThemeData(
      style: _baseStyle(foregroundColor: Colors.white).copyWith(
        backgroundColor: WidgetStateProperty.all(AppColors.brandPrimary),
      ),
    );
  }

  static OutlinedButtonThemeData outlinedButtonTheme({
    required ColorScheme colorScheme,
  }) {
    return OutlinedButtonThemeData(
      style: _baseStyle(foregroundColor: AppColors.brandPrimary).copyWith(
        side: WidgetStateProperty.all(
          const BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
      ),
    );
  }

  static TextButtonThemeData textButtonTheme({
    required ColorScheme colorScheme,
  }) {
    return TextButtonThemeData(
      style: _baseStyle(
        foregroundColor: AppColors.brandPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
