import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_publisher/src/core/router/app_routes.dart';
import 'package:smart_publisher/src/core/router/route_names.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/help_center/presentation/screens/help_center_screen.dart';
import 'package:smart_publisher/src/features/help_center/presentation/screens/user_guide_screen.dart';

import '../../helpers/localized_test_app.dart';
import '../../helpers/organization_role_fixtures.dart';

OrganizationAccessState _ownerAccess() {
  final membership = OrganizationEntity(
    id: 1,
    name: 'Test Org',
    slug: 'test-org',
    role: 'owner',
    isCurrent: true,
    permissions: permissionsForRole('owner'),
  );
  return OrganizationAccessState.active(
    memberships: <OrganizationEntity>[membership],
    currentOrganization: membership,
  );
}

void main() {
  testWidgets(
    'the search field navigates into the full guide with the typed query',
    (tester) async {
      // The guide's Sliver-based ListView only mounts elements within the
      // viewport + cache extent — "Telegram" matches several sections, so a
      // tall viewport avoids scrolling to find the match (same pattern as
      // create_post_screen_test.dart).
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _testRouter(RouteNames.helpCenterPath);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            currentOrganizationAccessProvider.overrideWith(
              (ref) async => _ownerAccess(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HelpCenterScreen), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Telegram');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(UserGuideScreen), findsOneWidget);
      expect(find.text('ربط Telegram'), findsOneWidget);
    },
  );

  testWidgets('renders a no-organization notice without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          currentOrganizationAccessProvider.overrideWith(
            (ref) async => OrganizationAccessState.noActiveOrganization(
              memberships: const <OrganizationEntity>[],
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          home: HelpCenterScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'You are not a member of any organization yet — some guide sections will only make sense once you join one.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

GoRouter _testRouter(String initialLocation) {
  return GoRouter(initialLocation: initialLocation, routes: appRoutes);
}
