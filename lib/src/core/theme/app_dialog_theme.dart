import 'package:flutter/material.dart';
import 'app_elevation.dart';
import 'app_radius.dart';

final class AppDialogTheme {
  AppDialogTheme._();

  static DialogThemeData theme({required ColorScheme colorScheme}) {
    return DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.level3,
      shadowColor: colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }
}
