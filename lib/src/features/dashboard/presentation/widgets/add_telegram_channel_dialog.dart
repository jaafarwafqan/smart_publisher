import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';

/// Telegram bots can't list the channels they administer — the user must
/// supply the channel's @username or numeric chat id, which is then verified
/// server-side. Returns the entered identifier, or null if cancelled.
Future<String?> showAddTelegramChannelDialog(BuildContext context) {
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    animationStyle: const AnimationStyle(
      duration: AppDuration.normal,
      reverseDuration: AppDuration.fast,
      curve: AppCurves.standard,
      reverseCurve: AppCurves.standard,
    ),
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.addTelegramChannelTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.addTelegramChannelBody),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.addTelegramChannelLabel,
                hintText: l10n.addTelegramChannelHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final identifier = controller.text.trim();
              Navigator.of(context).pop(identifier.isEmpty ? null : identifier);
            },
            child: Text(l10n.addTelegramChannelAdd),
          ),
        ],
      );
    },
  );
}
