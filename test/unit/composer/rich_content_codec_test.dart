import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/composer/domain/rich_content_codec.dart';

void main() {
  test(
    'legacy lite Markdown becomes visual Delta and preserves publish text',
    () {
      final controller = RichContentCodec.controllerFromStorage(
        body: 'خبر **مهم** عن #خبر_عاجل',
      );
      addTearDown(controller.dispose);

      expect(RichContentCodec.toPlainText(controller), 'خبر مهم عن #خبر_عاجل');
      expect(
        RichContentCodec.toPublishText(controller),
        'خبر **مهم** عن #خبر_عاجل',
      );
      expect(RichContentCodec.toDelta(controller), isNotEmpty);
    },
  );

  test(
    'WYSIWYG underline and bold never put literal Markdown in editor text',
    () {
      final controller = RichContentCodec.controllerFromStorage(body: '');
      addTearDown(controller.dispose);

      controller.formatSelection(quill.Attribute.bold);
      controller.replaceText(
        0,
        0,
        'عنوان',
        const TextSelection.collapsed(offset: 5),
      );
      controller.formatSelection(quill.Attribute.underline);
      controller.replaceText(
        5,
        0,
        ' جديد',
        const TextSelection.collapsed(offset: 10),
      );

      expect(RichContentCodec.toPlainText(controller), 'عنوان جديد');
      expect(RichContentCodec.toPlainText(controller), isNot(contains('**')));
      expect(RichContentCodec.toPublishText(controller), contains('**عنوان**'));
    },
  );

  test(
    'a hyperlink is preserved in the publish text, not silently dropped',
    () {
      final controller = RichContentCodec.controllerFromStorage(body: '');
      addTearDown(controller.dispose);

      controller.replaceText(
        0,
        0,
        'اضغط هنا',
        const TextSelection.collapsed(offset: 8),
      );
      controller.formatText(
        0,
        8,
        quill.LinkAttribute('https://example.test/a'),
      );

      // The editor shows only the anchor text — the URL must not vanish
      // from the actual published content, which is plain text and cannot
      // carry a separate href the way the editor's Delta can.
      expect(RichContentCodec.toPlainText(controller), 'اضغط هنا');
      expect(
        RichContentCodec.toPublishText(controller),
        'اضغط هنا (https://example.test/a)',
      );
    },
  );

  test(
    'a bare URL turned into a link is not duplicated in the publish text',
    () {
      final controller = RichContentCodec.controllerFromStorage(body: '');
      addTearDown(controller.dispose);

      const url = 'https://example.test/a';
      controller.replaceText(
        0,
        0,
        url,
        const TextSelection.collapsed(offset: url.length),
      );
      controller.formatText(0, url.length, quill.LinkAttribute(url));

      expect(RichContentCodec.toPublishText(controller), url);
    },
  );

  test('stored Delta reopens without requiring a Markdown round trip', () {
    final source = RichContentCodec.controllerFromStorage(body: 'نص');
    addTearDown(source.dispose);
    source.formatSelection(quill.Attribute.italic);
    source.replaceText(0, 0, 'واضح', const TextSelection.collapsed(offset: 4));

    final reopened = RichContentCodec.controllerFromStorage(
      body: RichContentCodec.toPublishText(source),
      richContent: RichContentCodec.toDelta(source),
    );
    addTearDown(reopened.dispose);

    expect(RichContentCodec.toPlainText(reopened), 'واضحنص');
    expect(RichContentCodec.toPublishText(reopened), '_واضح_نص');
  });
}
