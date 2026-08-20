import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Was calling _dartSources() (a full recursive Directory.listSync over
  // lib/) separately in each test() below, and re-reading every matched
  // file's content once per test — walking the whole source tree and
  // re-reading every file from disk twice per run for two independent regex
  // checks that could share one pass. Read once here instead; both tests
  // below reuse the same in-memory map.
  late final Map<String, String> sources;

  setUpAll(() {
    sources = <String, String>{
      for (final file in _dartSources()) file.path: file.readAsStringSync(),
    };
  });

  test('icon-only controls expose a tooltip in every source file', () {
    for (final entry in sources.entries) {
      final iconButtons = RegExp(
        r'IconButton\s*\(',
      ).allMatches(entry.value).length;
      final tooltips = RegExp(r'\btooltip\s*:').allMatches(entry.value).length;

      expect(
        tooltips,
        greaterThanOrEqualTo(iconButtons),
        reason:
            '${entry.key} has $iconButtons IconButton controls but only '
            '$tooltips accessible tooltips.',
      );
    }
  });

  test('custom tap targets declare a semantic boundary', () {
    for (final entry in sources.entries) {
      final hasCustomTapTarget = RegExp(
        r'\b(?:InkWell|GestureDetector)\s*\(',
      ).hasMatch(entry.value);
      if (!hasCustomTapTarget) {
        continue;
      }

      expect(
        entry.value,
        contains('Semantics('),
        reason:
            '${entry.key} contains a custom tap target without a '
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
