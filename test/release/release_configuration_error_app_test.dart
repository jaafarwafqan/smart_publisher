import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/app/bootstrap.dart';

/// Regression test for a real, live-caught bug: an incomplete/non-HTTPS
/// release configuration used to make the entire app a permanent blank
/// white screen with zero on-screen feedback, since
/// LaravelApi.assertReleaseConfiguration()'s StateError threw before
/// runApp() was ever called and runZonedGuarded's handler only logs, never
/// renders anything. bootstrap() now catches that specific error and
/// renders this screen instead — this test proves the screen itself
/// renders standalone (no ProviderScope/localization/network setup),
/// exactly as it would need to when the app's own configuration can't be
/// trusted enough to bootstrap normally.
void main() {
  testWidgets(
    'ReleaseConfigurationErrorApp renders the error message with no external dependencies',
    (tester) async {
      const message =
          'Release builds require HTTPS SP_API_BASE_URL, SP_AUTH_BASE_URL, and '
          'SP_OAUTH_BASE_URL dart-defines.';

      await tester.pumpWidget(
        const ReleaseConfigurationErrorApp(message: message),
      );
      await tester.pump();

      expect(find.text(message), findsOneWidget);
      expect(find.text('Configuration error — إعداد غير صحيح'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      // Confirms this really is a self-contained MaterialApp (its own
      // Directionality/Navigator), not a widget that assumes an ambient
      // ProviderScope or MaterialApp is already present above it.
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}
