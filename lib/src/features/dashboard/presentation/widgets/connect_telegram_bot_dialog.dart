import 'package:flutter/material.dart';
import 'package:smart_publisher/l10n/app_localizations.dart';

/// Real Telegram has no OAuth — connecting means providing a Bot Token
/// created via @BotFather. Returns the entered token, or null if cancelled.
Future<String?> showConnectTelegramBotDialog(BuildContext context) {
  final controller = TextEditingController();
  final l10n = AppLocalizations.of(context)!;
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.connectTelegramBotTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.connectTelegramBotBody),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.connectTelegramBotLabel,
                hintText: '123456789:AA...',
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
              final token = controller.text.trim();
              Navigator.of(context).pop(token.isEmpty ? null : token);
            },
            child: Text(l10n.connectTelegramBotConnect),
          ),
        ],
      );
    },
  );
}
