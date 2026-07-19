import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_extensions.dart';
import 'app_text_theme.dart';
import 'app_button_theme.dart';
import 'app_input_theme.dart';
import 'app_card_theme.dart';
import 'app_bar_theme.dart';
import 'app_dialog_theme.dart';
import 'app_navigation_theme.dart';

final class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return _build(Brightness.light);
  }

  static ThemeData dark() {
    return _build(Brightness.dark);
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brandPrimary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.brandPrimary,
          onPrimary: Colors.white,
          secondary: AppColors.brandSecondary,
          onSecondary: Colors.white,
          surface: isDark
              ? AppColors.backgroundDark
              : AppColors.backgroundLight,
          onSurface: isDark ? Colors.white : AppColors.textPrimary,
          surfaceContainer: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          surfaceContainerHighest: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFF1F5F9),
          outline: isDark ? AppColors.brandSecondary : AppColors.border,
          outlineVariant: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          inverseSurface: isDark
              ? AppColors.surfaceLight
              : AppColors.surfaceDark,
          onInverseSurface: isDark ? AppColors.textPrimary : Colors.white,
          scrim: Colors.black54,
          shadow: const Color(0x1F000000),
          error: AppColors.error,
          onError: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: colorScheme.surface,

      extensions: const [brandColorsExtension],

      textTheme: AppTextTheme.textTheme(brightness),
      inputDecorationTheme: AppInputTheme.theme(colorScheme: colorScheme),
      cardTheme: AppCardTheme.theme(colorScheme: colorScheme),
      appBarTheme: AppAppBarTheme.theme(colorScheme: colorScheme),

      navigationBarTheme: AppNavigationTheme.navigationBarTheme(
        colorScheme: colorScheme,
      ),

      navigationDrawerTheme: AppNavigationTheme.navigationDrawerTheme(
        colorScheme: colorScheme,
      ),

      dialogTheme: AppDialogTheme.theme(colorScheme: colorScheme),

      elevatedButtonTheme: AppButtonTheme.elevatedButtonTheme(
        colorScheme: colorScheme,
      ),
      filledButtonTheme: AppButtonTheme.filledButtonTheme(
        colorScheme: colorScheme,
      ),
      outlinedButtonTheme: AppButtonTheme.outlinedButtonTheme(
        colorScheme: colorScheme,
      ),
      textButtonTheme: AppButtonTheme.textButtonTheme(colorScheme: colorScheme),
    );
  }
}
