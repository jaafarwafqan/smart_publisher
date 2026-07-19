import 'package:flutter/material.dart';
import 'app_radius.dart';

final class AppNavigationTheme {
  AppNavigationTheme._();

  /// Navigation Bar Theme
  static NavigationBarThemeData navigationBarTheme({
    required ColorScheme colorScheme,
  }) {
    return NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 72,

      indicatorColor: colorScheme.secondaryContainer,

      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final selected = states.contains(WidgetState.selected);

        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),

      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        final selected = states.contains(WidgetState.selected);

        return IconThemeData(
          size: 24,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),
    );
  }

  /// Navigation Drawer Theme
  static NavigationDrawerThemeData navigationDrawerTheme({
    required ColorScheme colorScheme,
  }) {
    return NavigationDrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,

      elevation: 1,

      shadowColor: Colors.transparent,

      tileHeight: 56,

      indicatorColor: colorScheme.secondaryContainer,

      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),

      labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
        final selected = states.contains(WidgetState.selected);

        return TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? colorScheme.primary : colorScheme.onSurface,
        );
      }),

      iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
        final selected = states.contains(WidgetState.selected);

        return IconThemeData(
          size: 24,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        );
      }),
    );
  }
}
