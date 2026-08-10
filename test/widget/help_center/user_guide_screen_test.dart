import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/help_center/presentation/screens/user_guide_screen.dart';

import '../../helpers/localized_test_app.dart';
import '../../helpers/organization_role_fixtures.dart';

OrganizationAccessState _accessFor(String role) {
  final membership = OrganizationEntity(
    id: 1,
    name: 'Test Org',
    slug: 'test-org',
    role: role,
    isCurrent: true,
    permissions: permissionsForRole(role),
  );
  return OrganizationAccessState.active(
    memberships: <OrganizationEntity>[membership],
    currentOrganization: membership,
  );
}

Future<void> _pump(WidgetTester tester, OrganizationAccessState? access) async {
  // The guide is a long scrollable list (role table + up to 18 accordion
  // sections) — Sliver-based ListView only mounts elements within the
  // viewport + cache extent, so at the default test surface size most
  // sections never build at all. Use a tall viewport instead of scrolling
  // to each one (same pattern as create_post_screen_test.dart).
  tester.view.physicalSize = const Size(1200, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        currentOrganizationAccessProvider.overrideWith((ref) async {
          if (access == null) {
            return OrganizationAccessState.noActiveOrganization(
              memberships: const <OrganizationEntity>[],
            );
          }
          return access;
        }),
      ],
      child: const MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: UserGuideScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a Viewer never sees the Facebook-connect or member-management guide',
    (tester) async {
      await _pump(tester, _accessFor('viewer'));

      expect(find.text('ربط حساب Facebook'), findsNothing);
      expect(find.text('إدارة أعضاء المؤسسة'), findsNothing);
      // But read-only sections everyone gets stay visible.
      expect(find.text('البدء باستخدام النظام'), findsOneWidget);
      expect(find.text('التقويم'), findsOneWidget);
    },
  );

  testWidgets(
    'an Editor sees the approval-request guide but not direct-publish or approve/reject',
    (tester) async {
      await _pump(tester, _accessFor('editor'));

      expect(find.text('نشر المحرر وطلب الموافقة'), findsOneWidget);
      expect(find.text('النشر المباشر'), findsNothing);
      expect(find.text('الموافقة والرفض'), findsNothing);
    },
  );

  testWidgets('a Manager sees the connect-accounts and approve/reject guides', (
    tester,
  ) async {
    await _pump(tester, _accessFor('manager'));

    expect(find.text('ربط حساب Facebook'), findsOneWidget);
    expect(find.text('الموافقة والرفض'), findsOneWidget);
    // Member management stays Admin/Owner-only even for Manager.
    expect(find.text('إدارة أعضاء المؤسسة'), findsNothing);
  });

  testWidgets('an Admin sees the member-management guide', (tester) async {
    await _pump(tester, _accessFor('admin'));

    expect(find.text('إدارة أعضاء المؤسسة'), findsOneWidget);
    expect(find.text('إعدادات المؤسسة'), findsOneWidget);
  });

  testWidgets(
    'an Owner sees every section, including the most sensitive ones',
    (tester) async {
      await _pump(tester, _accessFor('owner'));

      expect(find.text('إدارة أعضاء المؤسسة'), findsOneWidget);
      expect(find.text('إعدادات المؤسسة'), findsOneWidget);
      expect(find.text('الموافقة والرفض'), findsOneWidget);
      expect(find.text('ربط حساب Facebook'), findsOneWidget);
    },
  );

  testWidgets(
    'a user with no active organization still sees the getting-started guide',
    (tester) async {
      await _pump(tester, null);

      expect(find.text('البدء باستخدام النظام'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('searching narrows sections and clearing restores them', (
    tester,
  ) async {
    await _pump(tester, _accessFor('owner'));

    expect(find.text('التقويم'), findsOneWidget);
    expect(find.text('مكتبة الوسائط'), findsOneWidget);

    // Typed as a partial word (not the exact section title) so the typed
    // value echoed by the TextField itself doesn't also satisfy
    // find.text('التقويم') below — "تقويم" is a substring match either way.
    await tester.enterText(find.byType(TextField).first, 'تقويم');
    await tester.pumpAndSettle();

    expect(find.text('التقويم'), findsOneWidget);
    expect(find.text('مكتبة الوسائط'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('التقويم'), findsOneWidget);
    expect(find.text('مكتبة الوسائط'), findsOneWidget);
  });

  testWidgets('an unmatched search shows the empty state', (tester) async {
    await _pump(tester, _accessFor('owner'));

    await tester.enterText(
      find.byType(TextField).first,
      'zzz_no_such_topic_zzz',
    );
    await tester.pumpAndSettle();

    // Chrome copy goes through AppLocalizations (English by default in
    // this harness — see localized_test_app.dart) unlike the guide's own
    // long-form Arabic content.
    expect(find.text('No results'), findsOneWidget);
  });

  testWidgets('renders in Arabic RTL with no layout overflow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          currentOrganizationAccessProvider.overrideWith(
            (ref) async => _accessFor('owner'),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          supportedLocales: testSupportedLocales,
          locale: Locale('ar'),
          home: UserGuideScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
