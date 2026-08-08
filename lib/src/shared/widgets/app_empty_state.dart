import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.showCard = true,
    this.alignment = CrossAxisAlignment.center,
  });

  final String message;
  final String? title;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool showCard;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment,
      children: <Widget>[
        Icon(
          icon,
          size: compact ? AppSizes.iconLg : AppSizes.iconXl,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        if (title != null) ...<Widget>[
          Text(
            title!,
            style: textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          message,
          style: textTheme.bodyMedium,
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.start,
        ),
        if (actionLabel != null && onAction != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );

    if (!showCard) {
      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: compact ? AppSpacing.sm : AppSpacing.lg,
        ),
        child: content,
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
        child: content,
      ),
    );
  }
}
