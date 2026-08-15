import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/composer/domain/lite_markdown.dart';

void main() {
  group('LiteMarkdown.toPlainText', () {
    test('strips bold and italic markers without leaving asterisks', () {
      expect(
        LiteMarkdown.toPlainText('Hello **world**, this is _great_!'),
        'Hello world, this is great!',
      );
    });

    test('leaves plain text untouched', () {
      expect(LiteMarkdown.toPlainText('Just plain text.'), 'Just plain text.');
    });

    test('never treats underscores inside hashtags as italic markers — Arabic '
        'hashtags routinely use them as a word separator since spaces are not '
        'allowed (reported live: four hashtags collapsed into two mangled, '
        'merged runs)', () {
      const caption =
          '#رسول_الله\n#وفاء_للحسين\n#شهر_صفر\n#العتبة_الحسينية_المقدسة';
      expect(LiteMarkdown.toPlainText(caption), caption);
    });

    test('still treats underscores at real word boundaries as italic', () {
      expect(
        LiteMarkdown.toPlainText('a snake_case_name and _real italic_ text'),
        'a snake_case_name and real italic text',
      );
    });
  });

  group('LiteMarkdown.toRuns', () {
    test('splits mixed plain/bold/italic text into three runs', () {
      final runs = LiteMarkdown.toRuns('This is **big** news, _really_.');

      expect(runs.map((r) => r.text).toList(), <String>[
        'This is ',
        'big',
        ' news, ',
        'really',
        '.',
      ]);
      expect(runs.map((r) => r.style).toList(), <LiteMarkdownStyle>[
        LiteMarkdownStyle.plain,
        LiteMarkdownStyle.bold,
        LiteMarkdownStyle.plain,
        LiteMarkdownStyle.italic,
        LiteMarkdownStyle.plain,
      ]);
    });

    test('a single run for text with no markers', () {
      final runs = LiteMarkdown.toRuns('No markers here.');

      expect(runs, hasLength(1));
      expect(runs.single.text, 'No markers here.');
      expect(runs.single.style, LiteMarkdownStyle.plain);
    });
  });
}
