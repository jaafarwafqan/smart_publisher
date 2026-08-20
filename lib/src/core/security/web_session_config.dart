import 'package:flutter/foundation.dart' show kIsWeb;

/// Browser cookie authentication is a deployment contract with the Laravel
/// API. Keep it opt-in for local development (where CORS often permits broad
/// localhost origins) and enable it in every hosted web build with
/// `--dart-define=SP_WEB_COOKIE_AUTH_ENABLED=true`.
final class WebSessionConfig {
  WebSessionConfig._();

  static const bool _enabledByBuild = bool.fromEnvironment(
    'SP_WEB_COOKIE_AUTH_ENABLED',
  );

  static bool get usesHttpOnlyCookies => kIsWeb && _enabledByBuild;
}
