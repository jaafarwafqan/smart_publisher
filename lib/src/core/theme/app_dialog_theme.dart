import 'package:flutter/material.dart';
import 'app_elevation.dart';
import 'app_radius.dart';
import 'app_text_theme.dart';

final class AppDialogTheme {
  AppDialogTheme._();

  static DialogThemeData theme({required ColorScheme colorScheme}) {
    final textTheme = AppTextTheme.textTheme(colorScheme.brightness);
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level3,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
