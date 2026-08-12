import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/application/facebook_native_login_service.dart';

/// The mobile flutter_facebook_auth SDK flow (2026-08 spec item 2) must
/// only ever be attempted on a real Android/iOS build — DashboardScreen.
/// _connectFacebook() gates on isSupportedOnThisPlatform before ever
/// touching the SDK, so this is the one thing about the service that's
/// meaningfully unit-testable without a platform channel (FacebookAuth
/// .instance.login() itself requires a real native SDK, mocked at the
/// integration level instead).
void main() {
  const service = FacebookNativeLoginService();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('is supported on a real Android build', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(service.isSupportedOnThisPlatform, isTrue);
  });

  test('is supported on a real iOS build', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(service.isSupportedOnThisPlatform, isTrue);
  });

  test(
    'is not supported on desktop platforms — the browser OAuth flow stays the only path there',
    () {
      for (final platform in <TargetPlatform>[
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ]) {
        debugDefaultTargetPlatformOverride = platform;
        expect(
          service.isSupportedOnThisPlatform,
          isFalse,
          reason: '$platform must keep using the browser OAuth flow',
        );
      }
    },
  );
}
