import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('icon-only controls expose a tooltip in every source file', () {
    for (final file in _dartSources()) {
      final source = file.readAsStringSync();
      final iconButtons = RegExp(r'IconButton\s*\(').allMatches(source).length;
      final tooltips = RegExp(r'\btooltip\s*:').allMatches(source).length;

      expect(
        tooltips,
        greaterThanOrEqualTo(iconButtons),
        reason:
            '${file.path} has $iconButtons IconButton controls but only '
            '$tooltips accessible tooltips.',
      );
    }
  });

  test('custom tap targets declare a semantic boundary', () {
    for (final file in _dartSources()) {
      final source = file.readAsStringSync();
      final hasCustomTapTarget = RegExp(
        r'\b(?:InkWell|GestureDetector)\s*\(',
      ).hasMatch(source);
      if (!hasCustomTapTarget) {
        continue;
      }

      expect(
        source,
        contains('Semantics('),
        reason:
            '${file.path} contains a custom tap target without a '
            'Semantics boundary.',
      );
    }
  });
}

Iterable<File> _dartSources() {
  return Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}
