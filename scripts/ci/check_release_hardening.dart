#!/usr/bin/env dart
// Fail-closed source hygiene checks for release pipelines.
//
// This repository has no Docker image today. The checks nevertheless protect
// the root Docker context that a future image would use, and reject tracked
// environment files and common signing/key material before an image or release
// can be produced. They use only the Dart SDK and make no network requests.

import 'dart:convert';
import 'dart:io';

final repositoryRoot = File.fromUri(Platform.script).parent.parent.parent;

const allowedEnvironmentTemplates = {
  '.env.example',
  '.env.sample',
  '.env.template',
};

const sensitiveSuffixes = {'.pem', '.key', '.p12', '.pfx', '.jks', '.keystore'};

const requiredIgnorePatterns = {
  '.env',
  '.env.*',
  '*.env',
  '.envrc',
  '*.pem',
  '*.key',
  '*.p12',
  '*.pfx',
  '*.jks',
  '*.keystore',
};

const workflowPaths = [
  '.github/workflows/ci.yml',
  '.github/workflows/release.yml',
];

const releaseDeployScriptPath = 'scripts/release/deploy_release.sh';

const androidReleaseTest =
    'flutter test test/release/android_release_configuration_test.dart';

const androidReleaseSigningInputs = [
  'ANDROID_RELEASE_KEYSTORE_BASE64',
  'ANDROID_RELEASE_STORE_FILE',
  'ANDROID_RELEASE_STORE_PASSWORD',
  'ANDROID_RELEASE_KEY_ALIAS',
  'ANDROID_RELEASE_KEY_PASSWORD',
];

const releaseNetworkInputs = [
  'SP_API_BASE_URL',
  'SP_AUTH_BASE_URL',
  'SP_OAUTH_BASE_URL',
];

void main() {
  final errors = <String>[];
  _validateIgnorePolicies(errors);
  _validateTrackedSensitiveFiles(errors);
  _validateDockerSources(errors);
  _validateWorkflowGates(errors);
  _validateClosedBetaDistribution(errors);

  if (errors.isNotEmpty) {
    stderr.writeln('Release hardening check failed:');
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Release hardening check passed: no tracked environment/key material or '
    'unsafe Docker source found.',
  );
}

void _validateClosedBetaDistribution(List<String> errors) {
  final script = File(_rootPath(releaseDeployScriptPath));
  if (!script.existsSync()) {
    errors.add(
      'Missing closed-beta distribution script: $releaseDeployScriptPath',
    );
    return;
  }

  final contents = script.readAsStringSync();
  for (final requiredInput in [
    'FIREBASE_APP_ID_ANDROID',
    'FIREBASE_TOKEN',
    'FIREBASE_TESTER_GROUPS',
  ]) {
    if (!contents.contains(': "\${$requiredInput:?')) {
      errors.add(
        '$releaseDeployScriptPath: must fail closed when $requiredInput is absent.',
      );
    }
  }
  if (contents.contains('Skipping Firebase') ||
      contents.contains('WEB_DEPLOY_TARGET')) {
    errors.add(
      '$releaseDeployScriptPath: must not silently skip closed-beta distribution.',
    );
  }
}

void _validateIgnorePolicies(List<String> errors) {
  for (final policyName in ['.gitignore', '.dockerignore']) {
    final policyFile = File(_rootPath(policyName));
    if (!policyFile.existsSync()) {
      errors.add('Missing required ignore policy: $policyName');
      continue;
    }

    final patterns = policyFile
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toSet();
    final missing = requiredIgnorePatterns.difference(patterns).toList()
      ..sort();
    if (missing.isNotEmpty) {
      errors.add('$policyName: missing ignore patterns: ${missing.join(', ')}');
    }
  }
}

void _validateTrackedSensitiveFiles(List<String> errors) {
  for (final path in _trackedFiles()) {
    if (_isDisallowedSensitivePath(path)) {
      errors.add('Tracked sensitive file is forbidden: $path');
    }
  }
}

void _validateDockerSources(List<String> errors) {
  final explicitSecretCopy = RegExp(
    r'^\s*(?:COPY|ADD)\s+(?:--\S+\s+)*(?:.*?)(?:\.env(?:\b|\.)|'
    r'(?:\.pem|\.key|\.p12|\.pfx|\.jks|\.keystore)\b|key\.properties\b)',
    caseSensitive: false,
    multiLine: true,
  );
  final buildTimeLaravelCache = RegExp(
    r'\b(?:php\s+artisan\s+)?(?:config|route):cache\b',
    caseSensitive: false,
  );

  for (final path in _trackedFiles().where(_isDockerfile)) {
    final dockerfile = File(_rootPath(path));
    final contents = dockerfile.readAsStringSync();
    if (explicitSecretCopy.hasMatch(contents)) {
      errors.add(
        '$path: must not COPY or ADD environment files or key material.',
      );
    }
    if (buildTimeLaravelCache.hasMatch(contents)) {
      errors.add(
        '$path: must not build Laravel config or route caches before runtime '
        'environment values exist.',
      );
    }
  }
}

void _validateWorkflowGates(List<String> errors) {
  const gatePatterns = {
    'gitleaks': r'gitleaks/gitleaks-action@',
    'static analysis': r'\bflutter analyze\b',
    'Flutter tests': r'\bflutter test\b',
  };
  final continueOnError = RegExp(r'^\s*continue-on-error\s*:', multiLine: true);

  for (final path in workflowPaths) {
    final workflow = File(_rootPath(path));
    if (!workflow.existsSync()) {
      errors.add('Missing release gate workflow: $path');
      continue;
    }

    final contents = workflow.readAsStringSync();
    if (!contents.contains(androidReleaseTest)) {
      errors.add(
        '$path: must run the Android release configuration regression test.',
      );
    }

    if (path == '.github/workflows/release.yml') {
      for (final input in androidReleaseSigningInputs) {
        if (!contents.contains(input)) {
          errors.add(
            '$path: release signing must source $input from the CI secret store.',
          );
        }
      }
      if (!contents.contains('Materialize Android release keystore')) {
        errors.add(
          '$path: missing ephemeral Android keystore materialization step.',
        );
      }
      for (final input in releaseNetworkInputs) {
        if (!contents.contains(input) ||
            !contents.contains('--dart-define=$input=')) {
          errors.add(
            '$path: release build must require and compile in HTTPS $input.',
          );
        }
      }
    }

    final blocks = _workflowStepBlocks(contents);
    for (final entry in gatePatterns.entries) {
      final pattern = RegExp(entry.value);
      final matchingBlocks = blocks.where(pattern.hasMatch).toList();
      if (matchingBlocks.isEmpty) {
        errors.add('$path: missing fail-closed ${entry.key} gate.');
        continue;
      }
      if (matchingBlocks.any(continueOnError.hasMatch)) {
        errors.add('$path: ${entry.key} must not use continue-on-error.');
      }
    }
  }
}

List<String> _trackedFiles() {
  final result = Process.runSync('git', [
    'ls-files',
    '-z',
  ], workingDirectory: repositoryRoot.path);
  if (result.exitCode != 0) {
    throw StateError('Unable to enumerate tracked files with git.');
  }

  return (result.stdout as String)
      .split('\u0000')
      .where((path) => path.isNotEmpty)
      .toList(growable: false);
}

bool _isDisallowedSensitivePath(String path) {
  final filename = path.split('/').last.toLowerCase();
  if (allowedEnvironmentTemplates.contains(filename)) {
    return false;
  }

  if (filename == '.env' ||
      filename.startsWith('.env.') ||
      filename.endsWith('.env') ||
      filename == '.envrc') {
    return true;
  }

  return sensitiveSuffixes.any(filename.endsWith) ||
      {
        'key.properties',
        'id_rsa',
        'id_dsa',
        'id_ecdsa',
        'id_ed25519',
      }.contains(filename);
}

bool _isDockerfile(String path) =>
    path.split('/').last.toLowerCase().startsWith('dockerfile');

List<String> _workflowStepBlocks(String contents) {
  final lines = const LineSplitter().convert(contents);
  final starts = <({int index, int indentation})>[];
  final stepStart = RegExp(r'^(\s*)-\s+name:\s+');

  for (var index = 0; index < lines.length; index++) {
    final match = stepStart.firstMatch(lines[index]);
    if (match != null) {
      starts.add((index: index, indentation: match.group(1)!.length));
    }
  }

  final blocks = <String>[];
  for (var offset = 0; offset < starts.length; offset++) {
    final start = starts[offset];
    var end = lines.length;
    for (final candidate in starts.skip(offset + 1)) {
      if (candidate.indentation <= start.indentation) {
        end = candidate.index;
        break;
      }
    }
    blocks.add(lines.sublist(start.index, end).join('\n'));
  }
  return blocks;
}

String _rootPath(String relativePath) =>
    '${repositoryRoot.path}${Platform.pathSeparator}$relativePath';
