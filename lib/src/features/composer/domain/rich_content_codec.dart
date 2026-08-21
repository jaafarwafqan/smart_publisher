import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'lite_markdown.dart';

/// The editor owns a Quill Delta; the existing `content` field remains the
/// safe, backward-compatible publishing representation.  A legacy plain or
/// lite-Markdown body is converted on read, never discarded.
final class RichContentCodec {
  RichContentCodec._();

  static quill.QuillController controllerFromStorage({
    required String body,
    List<Map<String, dynamic>> richContent = const <Map<String, dynamic>>[],
  }) {
    return quill.QuillController(
      document: documentFromStorage(body: body, richContent: richContent),
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  static quill.Document documentFromStorage({
    required String body,
    List<Map<String, dynamic>> richContent = const <Map<String, dynamic>>[],
  }) {
    if (richContent.isNotEmpty) {
      try {
        return quill.Document.fromJson(richContent);
      } catch (_) {
        // An older/corrupt optional editor representation never prevents a
        // post from opening: the authoritative legacy body remains usable.
      }
    }
    return _legacyDocument(body);
  }

  static quill.Document documentFromPlainText(String text) {
    final normalized = text.endsWith('\n') ? text : '$text\n';
    return quill.Document.fromJson(<Map<String, dynamic>>[
      <String, dynamic>{'insert': normalized},
    ]);
  }

  static List<Map<String, dynamic>> toDelta(quill.QuillController controller) {
    return controller.document
        .toDelta()
        .toJson()
        .map((operation) => Map<String, dynamic>.from(operation as Map))
        .toList(growable: false);
  }

  static String toPlainText(quill.QuillController controller) {
    return controller.document.toPlainText().trimRight();
  }

  /// Converts only the subset the live publishing pipeline supports. Bold
  /// and italic become legacy markers for Telegram's server-side sanitizer;
  /// all other attributes remain safely represented in the stored Delta and
  /// are rendered as clean plain text where targets do not support them.
  static String toPublishText(quill.QuillController controller) {
    final output = StringBuffer();
    for (final rawOperation in controller.document.toDelta().toJson()) {
      final operation = Map<String, dynamic>.from(rawOperation as Map);
      final insert = operation['insert'];
      if (insert is! String) {
        continue;
      }
      final attributes = operation['attributes'];
      final styles = attributes is Map
          ? Map<String, dynamic>.from(attributes)
          : const <String, dynamic>{};
      var segment = insert;
      if (styles['italic'] == true && segment.trim().isNotEmpty) {
        segment = '_${segment}_';
      }
      if (styles['bold'] == true && segment.trim().isNotEmpty) {
        segment = '**$segment**';
      }
      output.write(segment);
    }
    return output.toString().trimRight();
  }

  static String selectedText(quill.QuillController controller) {
    final selection = controller.selection;
    if (!selection.isValid || selection.isCollapsed) {
      return '';
    }
    return controller.document
        .getPlainText(selection.start, selection.end - selection.start)
        .trimRight();
  }

  static quill.Document _legacyDocument(String body) {
    final operations = <Map<String, dynamic>>[];
    for (final run in LiteMarkdown.toRuns(body)) {
      final attributes = <String, dynamic>{
        if (run.style == LiteMarkdownStyle.bold) 'bold': true,
        if (run.style == LiteMarkdownStyle.italic) 'italic': true,
      };
      operations.add(<String, dynamic>{
        'insert': run.text,
        if (attributes.isNotEmpty) 'attributes': attributes,
      });
    }
    if (operations.isEmpty) {
      operations.add(<String, dynamic>{'insert': '\n'});
    } else {
      final lastText = operations.last['insert'] as String;
      if (!lastText.endsWith('\n')) {
        operations.add(<String, dynamic>{'insert': '\n'});
      }
    }
    return quill.Document.fromJson(operations);
  }
}
