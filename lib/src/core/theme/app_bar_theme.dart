import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_elevation.dart';

final class AppAppBarTheme {
  // غيرنا الاسم هنا
  AppAppBarTheme._();

  static AppBarTheme theme({required ColorScheme colorScheme}) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AppBarTheme(
      elevation: AppElevation.level0,
      scrolledUnderElevation: AppElevation.level0,
      centerTitle: true,
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
      iconTheme: IconThemeData(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      systemOverlayStyle: overlayStyle,
    );
  }
}
