/// Dart mirror of `app/Support/LiteMarkdown.php` — same regex rules, kept in
/// sync by hand. Used only to render an accurate composer preview; the
/// backend transform is what actually ships to each platform at publish
/// time, since only Telegram's real API can render bold/italic at all.
class LiteMarkdown {
  LiteMarkdown._();

  static final RegExp _bold = RegExp(r'\*\*(.+?)\*\*', dotAll: true);

  // CommonMark's own rule for this exact ambiguity: `_` immediately
  // adjacent to a letter/digit ("intraword") never opens/closes emphasis —
  // without it, any hashtag using underscores as a word separator (a
  // standard Arabic-hashtag convention, since spaces aren't allowed) gets
  // misread as italic markup, silently eating every underscore between the
  // first and last hashtag in the caption. Reproduced live: four hashtags
  // like #رسول_الله #وفاء_للحسين collapsed into two mangled, merged runs.
  // \w is ASCII-only in Dart regex (doesn't cover Arabic letters), so this
  // needs \p{L}/\p{N} + the unicode flag, not \b/\w.
  static final RegExp _italic = RegExp(
    r'(?<![\p{L}\p{N}])_(.+?)_(?![\p{L}\p{N}])',
    dotAll: true,
    unicode: true,
  );

  /// The plain text a non-Telegram platform will really display — markers
  /// stripped cleanly, never left as literal asterisks/underscores.
  static String toPlainText(String text) {
    final withoutBold = text.replaceAllMapped(_bold, (m) => m.group(1) ?? '');
    return withoutBold.replaceAllMapped(_italic, (m) => m.group(1) ?? '');
  }

  /// Splits [text] into alternating plain/bold/italic runs, in order, for a
  /// caller to render each run with the right style (e.g. via `TextSpan`) —
  /// mirrors what `LiteMarkdown::toTelegramHtml()` really sends to Telegram.
  static List<LiteMarkdownRun> toRuns(String text) {
    final runs = <LiteMarkdownRun>[];
    var cursor = 0;

    final combined = RegExp(
      r'\*\*(.+?)\*\*|(?<![\p{L}\p{N}])_(.+?)_(?![\p{L}\p{N}])',
      dotAll: true,
      unicode: true,
    );

    for (final match in combined.allMatches(text)) {
      if (match.start > cursor) {
        runs.add(LiteMarkdownRun.plain(text.substring(cursor, match.start)));
      }
      final bold = match.group(1);
      if (bold != null) {
        runs.add(LiteMarkdownRun.bold(bold));
      } else {
        runs.add(LiteMarkdownRun.italic(match.group(2) ?? ''));
      }
      cursor = match.end;
    }

    if (cursor < text.length) {
      runs.add(LiteMarkdownRun.plain(text.substring(cursor)));
    }

    return runs;
  }
}

enum LiteMarkdownStyle { plain, bold, italic }

class LiteMarkdownRun {
  const LiteMarkdownRun._(this.text, this.style);

  factory LiteMarkdownRun.plain(String text) =>
      LiteMarkdownRun._(text, LiteMarkdownStyle.plain);
  factory LiteMarkdownRun.bold(String text) =>
      LiteMarkdownRun._(text, LiteMarkdownStyle.bold);
  factory LiteMarkdownRun.italic(String text) =>
      LiteMarkdownRun._(text, LiteMarkdownStyle.italic);

  final String text;
  final LiteMarkdownStyle style;
}
