#!/usr/bin/env dart
// Phase 5 (UI/UX token discipline, 2026-08-16): fails closed on a raw
// spacing literal that exactly matches the AppSpacing scale
// (lib/src/core/theme/app_spacing.dart: 4/8/12/16/24/32) inside
// EdgeInsets.all()/symmetric()/only() or a standalone
// SizedBox(height:)/SizedBox(width:) spacer, anywhere under lib/src/features.
// AppSpacing itself already existed before this check — see
// docs/architecture/decisions/0007-persistent-local-caches-for-drafts-and-analytics.md's
// sibling entry in STATUS.md for why this check was added: the tokens
// existed but nothing stopped a new raw value from being added right next
// to them, and an audit found real drift (e.g. `EdgeInsets.all(16)` beside
// `EdgeInsets.all(AppSpacing.lg)` in the same file).
//
// Deliberately narrow, same spirit as check_release_hardening.dart: does
// NOT flag EdgeInsets.fromLTRB (positional, harder to attribute safely), a
// bare `height:`/`width:` on any other widget (Container/Image/
// ConstrainedBox — a real fixed pixel dimension there, not spacing), or any
// value that doesn't exactly match the token scale (a deliberately
// off-scale value is a design decision, not something this check second
// -guesses). Use only the Dart SDK, no network requests.

import 'dart:io';

const _scale = {
  '4',
  '4.0',
  '8',
  '8.0',
  '12',
  '12.0',
  '16',
  '16.0',
  '24',
  '24.0',
  '32',
  '32.0',
};

final _num = r'(-?\d+(?:\.\d+)?)';

void main() {
  final dir = Directory('lib/src/features');
  final violations = <String>[];

  final edgeInsetsAll = RegExp('EdgeInsets\\.all\\($_num\\)');
  final namedParam = RegExp(
    '(horizontal|vertical|left|top|right|bottom):\\s*$_num(?=[,)])',
  );
  final sizedBox = RegExp('SizedBox\\((height|width): $_num\\)');

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final path = entity.path.replaceAll('\\', '/');

      for (final match in edgeInsetsAll.allMatches(line)) {
        if (_scale.contains(match.group(1))) {
          violations.add(
            '$path:${i + 1}: raw EdgeInsets.all(${match.group(1)}) — use an AppSpacing token.',
          );
        }
      }
      for (final match in namedParam.allMatches(line)) {
        if (_scale.contains(match.group(2))) {
          violations.add(
            '$path:${i + 1}: raw ${match.group(1)}: ${match.group(2)} — use an AppSpacing token.',
          );
        }
      }
      for (final match in sizedBox.allMatches(line)) {
        if (_scale.contains(match.group(2))) {
          violations.add(
            '$path:${i + 1}: raw SizedBox(${match.group(1)}: ${match.group(2)}) — use an AppSpacing token.',
          );
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Spacing token check failed:');
    for (final violation in violations) {
      stderr.writeln('- $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Spacing token check passed: no raw on-scale spacing literal found under lib/src/features.',
  );
}
