import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

enum PillTone { neutral, success, warning, danger }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.labelStyle,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = _colorsFor(colorScheme);
    final foreground = foregroundColor ?? colors.foreground;

    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: AppSizes.iconSm, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style:
                labelStyle ??
                Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  _PillColors _colorsFor(ColorScheme colorScheme) {
    switch (tone) {
      case PillTone.success:
        return _PillColors(
          background: colorScheme.primaryContainer,
          foreground: colorScheme.onPrimaryContainer,
        );
      case PillTone.warning:
        return _PillColors(
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
        );
      case PillTone.danger:
        return _PillColors(
          background: colorScheme.errorContainer,
          foreground: colorScheme.onErrorContainer,
        );
      case PillTone.neutral:
        return _PillColors(
          background: colorScheme.surfaceContainerHighest,
          foreground: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _PillColors {
  const _PillColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
