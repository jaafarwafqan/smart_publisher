import 'package:flutter/material.dart';

import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

class ComposerReadiness extends StatelessWidget {
  const ComposerReadiness({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isReady = progress == 1;

    return Semantics(
      value: '${(progress * 100).round()}%',
      child: AnimatedContainer(
        duration: AppDuration.normal,
        curve: AppCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isReady
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: SizedBox(
                    height: AppSpacing.sm,
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: ColoredBox(
                            color: colorScheme.surface.withValues(alpha: 0.6),
                          ),
                        ),
                        AnimatedContainer(
                          duration: AppDuration.slow,
                          curve: AppCurves.standard,
                          width: constraints.maxWidth * progress,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedSwitcher(
              duration: AppDuration.fast,
              switchInCurve: AppCurves.standard,
              switchOutCurve: AppCurves.standard,
              child: Icon(
                isReady ? Icons.check_circle_outline : Icons.edit_note_outlined,
                key: ValueKey<bool>(isReady),
                color: isReady
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
