import 'package:flutter/foundation.dart';

/// DSN/environment are supplied at build time via `--dart-define`, same
/// convention as `LaravelApi`'s `SP_*` values. No DSN configured (the
/// default) means Sentry never initializes and [SentryCrashReporter] is
/// simply never selected — see bootstrap.dart.
final class SentryConfig {
  SentryConfig._();

  static const String dsn = String.fromEnvironment('SP_SENTRY_DSN');

  static const String environment = String.fromEnvironment(
    'SP_SENTRY_ENVIRONMENT',
    defaultValue: 'production',
  );

  /// Deliberately off in debug builds regardless of DSN: local `flutter run`
  /// sessions and widget/integration test runs must never file real Sentry
  /// events under the production project.
  static bool get isEnabled => !kDebugMode && dsn.isNotEmpty;
}
