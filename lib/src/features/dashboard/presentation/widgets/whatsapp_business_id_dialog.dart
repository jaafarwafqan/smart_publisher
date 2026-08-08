import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_duration.dart';

/// WhatsApp Business discovery needs a Meta Business ID to look up WhatsApp
/// Business Accounts and phone numbers — it can't always be derived from the
/// OAuth token alone. Returns the entered id, or null if cancelled.
Future<String?> showWhatsAppBusinessIdDialog(BuildContext context) {
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
        title: Text(l10n.whatsappBusinessIdTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.whatsappBusinessIdBody),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.whatsappBusinessIdLabel,
                hintText: '123456789012345',
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
              final businessId = controller.text.trim();
              Navigator.of(context).pop(businessId.isEmpty ? null : businessId);
            },
            child: Text(l10n.whatsappBusinessIdSave),
          ),
        ],
      );
    },
  );
}
