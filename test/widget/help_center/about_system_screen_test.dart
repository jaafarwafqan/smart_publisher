import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/help_center/presentation/screens/about_system_screen.dart';

import '../../helpers/localized_test_app.dart';

final _fakePackageInfo = PackageInfo(
  appName: 'Smart Publisher',
  packageName: 'com.smartpublisher.app',
  version: '9.9.9',
  buildNumber: '42',
);

Future<void> _pump(WidgetTester tester) async {
  // Eight stacked section cards (definition, goals, features, six platform
  // cards, roles, security, app info, team) — Sliver-based ListView only
  // mounts elements within the viewport + cache extent, so a tall viewport
  // avoids scrolling to reach the lower cards (same pattern as
  // create_post_screen_test.dart).
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        packageInfoProvider.overrideWith((ref) async => _fakePackageInfo),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: AboutSystemScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders without an authenticated session', (tester) async {
    // No auth/network provider is overridden at all — proves the screen
    // has zero dependency on a logged-in session, matching /about being
    // reachable both before and after login.
    await _pump(tester);

    expect(find.text('About Smart Publisher'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reads the version and build number from PackageInfo, not a hardcoded literal',
    (tester) async {
      await _pump(tester);

      expect(find.text('9.9.9'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      // The pubspec.yaml literal must never leak in as a fallback.
      expect(find.text('1.0.0'), findsNothing);
    },
  );

  testWidgets(
    'a mock-backed platform (Instagram) is labeled Coming soon, not Available',
    (tester) async {
      await _pump(tester);

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Coming soon'), findsWidgets);
    },
  );

  testWidgets('WhatsApp is never shown as available for publishing', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Partially available'), findsOneWidget);
    // "Publish: No" must be present for WhatsApp's card — publishPost()
    // throws "not implemented" on the real backend (verified 2026-08-10).
    expect(find.textContaining('Publish: No'), findsWidgets);
    expect(
      find.textContaining('Publish: Yes'),
      findsWidgets,
    ); // Facebook/Telegram do allow it.
  });

  testWidgets('never renders a token, secret, or API key value', (
    tester,
  ) async {
    await _pump(tester);

    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .join('\n');

    for (final forbidden in <String>[
      'access_token',
      'bot_token',
      'client_secret',
      'App Secret:',
    ]) {
      expect(
        texts.toLowerCase().contains(forbidden.toLowerCase()),
        isFalse,
        reason: forbidden,
      );
    }
  });

  testWidgets('renders in Arabic RTL with no layout overflow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          packageInfoProvider.overrideWith((ref) async => _fakePackageInfo),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: Locale('ar'),
          home: AboutSystemScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('حول الناشر الذكي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
