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

/// Scopes a finder to a single platform's status Card — several platforms
/// legitimately share the exact same readiness label/capability text (e.g.
/// WhatsApp and X both render "Partially available"), so an unscoped
/// `find.text(...)` can't tell them apart once more than one platform is in
/// the same state.
Finder _withinPlatformCard(
  WidgetTester tester,
  String platformLabel,
  Finder matching,
) {
  // .first: find.ancestor returns every matching ancestor up the tree, not
  // just the nearest one — the platform Card is itself nested inside the
  // section's own outer Card, so an unrestricted ancestor search matches
  // both and the descendant search below would then span every platform's
  // card, not just this one.
  final card = find
      .ancestor(of: find.text(platformLabel), matching: find.byType(Card))
      .first;
  return find.descendant(of: card, matching: matching);
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
    'a still fully mock-backed platform (LinkedIn) is labeled Coming soon, not Available',
    (tester) async {
      await _pump(tester);

      expect(find.text('LinkedIn'), findsOneWidget);
      expect(
        _withinPlatformCard(tester, 'LinkedIn', find.text('Coming soon')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Instagram (2026-08 graduation) is labeled Available (Beta), can publish, but cannot Connect directly',
    (tester) async {
      await _pump(tester);

      expect(find.text('Instagram'), findsOneWidget);
      expect(
        _withinPlatformCard(tester, 'Instagram', find.text('Available (Beta)')),
        findsOneWidget,
      );
      expect(
        _withinPlatformCard(
          tester,
          'Instagram',
          find.textContaining('Publish: Yes'),
        ),
        findsOneWidget,
      );
      // No OAuth of its own — discovered as a child of a connected
      // Facebook Page, see FacebookOAuthProvider::listPages() on the
      // backend and platformHelpStatuses()'s dedicated instagram branch.
      expect(
        _withinPlatformCard(
          tester,
          'Instagram',
          find.textContaining('Connect: No'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('WhatsApp is never shown as available for publishing', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('WhatsApp'), findsOneWidget);
    expect(
      _withinPlatformCard(tester, 'WhatsApp', find.text('Partially available')),
      findsOneWidget,
    );
    // "Publish: No" must be present for WhatsApp's card — publishPost()
    // throws "not implemented" on the real backend (verified 2026-08-10).
    expect(
      _withinPlatformCard(
        tester,
        'WhatsApp',
        find.textContaining('Publish: No'),
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Publish: Yes'),
      findsWidgets,
    ); // Facebook/Telegram/Instagram do allow it.
  });

  testWidgets(
    'X (Twitter) is Partially available — real code, not yet production-approved',
    (tester) async {
      await _pump(tester);

      expect(find.text('X'), findsOneWidget);
      expect(
        _withinPlatformCard(tester, 'X', find.text('Partially available')),
        findsOneWidget,
      );
      expect(
        _withinPlatformCard(tester, 'X', find.textContaining('Publish: No')),
        findsOneWidget,
      );
    },
  );

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
