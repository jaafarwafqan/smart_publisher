import 'package:flutter/material.dart';

final class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

final class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

final class AppPadding {
  AppPadding._();

  static const EdgeInsetsGeometry xs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsetsGeometry sm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsetsGeometry md = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsetsGeometry lg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsetsGeometry xl = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.lg,
  );
}

final class AppElevation {
  AppElevation._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 2;
  static const double level3 = 3;
}

final class AppAnimation {
  AppAnimation._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

final class AppIconSize {
  AppIconSize._();

  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
}
