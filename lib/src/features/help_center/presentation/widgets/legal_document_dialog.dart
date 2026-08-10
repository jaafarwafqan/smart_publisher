import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/theme/app_spacing.dart';

/// Opens the actual bundled `docs/legal/*.md` file — never an invented
/// external URL. `privacy_policy.md`/`terms_of_service.md`/`support.md`
/// are real files already reviewed and committed to this repository (see
/// `pubspec.yaml`'s `assets:`); showing their real text in-app is honest
/// where linking to a public HTTPS URL that doesn't exist yet would not
/// be — both documents say so explicitly ("must publish ... before public
/// rollout").
Future<void> showLegalDocumentDialog(
  BuildContext context, {
  required String title,
  required String assetPath,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) =>
        _LegalDocumentDialog(title: title, assetPath: assetPath),
  );
}

class _LegalDocumentDialog extends StatefulWidget {
  const _LegalDocumentDialog({required this.title, required this.assetPath});

  final String title;
  final String assetPath;

  @override
  State<_LegalDocumentDialog> createState() => _LegalDocumentDialogState();
}

class _LegalDocumentDialogState extends State<_LegalDocumentDialog> {
  late final Future<String> _content = rootBundle.loadString(widget.assetPath);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        height: 480,
        child: FutureBuilder<String>(
          future: _content,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              if (snapshot.hasError) {
                return const Center(child: Text('تعذّر تحميل هذا المستند.'));
              }
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: SelectableText(
                snapshot.data!,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
