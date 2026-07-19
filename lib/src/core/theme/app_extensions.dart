import 'package:flutter/material.dart';
import 'app_colors.dart';

class BrandColors extends ThemeExtension<BrandColors> {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color successContainer;
  final Color warningContainer;
  final Color infoContainer;
  final Color errorContainer;

  const BrandColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.successContainer,
    required this.warningContainer,
    required this.infoContainer,
    required this.errorContainer,
  });

  @override
  ThemeExtension<BrandColors> copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? successContainer,
    Color? warningContainer,
    Color? infoContainer,
    Color? errorContainer,
  }) {
    return BrandColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      successContainer: successContainer ?? this.successContainer,
      warningContainer: warningContainer ?? this.warningContainer,
      infoContainer: infoContainer ?? this.infoContainer,
      errorContainer: errorContainer ?? this.errorContainer,
    );
  }

  @override
  ThemeExtension<BrandColors> lerp(
    covariant ThemeExtension<BrandColors>? other,
    double t,
  ) {
    if (other is! BrandColors) return this;
    return BrandColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      errorContainer: Color.lerp(errorContainer, other.errorContainer, t)!,
    );
  }
}

// إنشاء نسخة موحدة لاستخدامها في الثيمين الفاتح والداكن (يمكنك فصلها لاحقاً لو أردت ألواناً مختلفة)
const brandColorsExtension = BrandColors(
  success: AppColors.success,
  warning: AppColors.warning,
  error: AppColors.error,
  info: AppColors.info,
  successContainer: Color(0xFFE8F5E9),
  warningContainer: Color(0xFFFFF8E1),
  infoContainer: Color(0xFFE3F2FD),
  errorContainer: Color(0xFFFEF2F2),
);
