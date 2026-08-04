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
