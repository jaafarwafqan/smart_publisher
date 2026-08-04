import 'package:flutter/material.dart';

/// Live-highlights `#hashtag` and `@mention` substrings as the user types —
/// both are real, valid plain text on every platform (unlike bold/italic
/// markers), so this is purely a visual aid with no publish-time transform.
class HighlightingTextEditingController extends TextEditingController {
  HighlightingTextEditingController({super.text});

  static final RegExp _hashtagOrMention = RegExp(r'(#\w+|@\w+)');

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <InlineSpan>[];
    final highlightStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    text.splitMapJoin(
      _hashtagOrMention,
      onMatch: (match) {
        children.add(TextSpan(text: match[0], style: highlightStyle));
        return '';
      },
      onNonMatch: (nonMatch) {
        children.add(TextSpan(text: nonMatch, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
