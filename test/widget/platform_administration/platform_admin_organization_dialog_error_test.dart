import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/platform_administration/presentation/screens/platform_admin_screens.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

/// Regression coverage for the two "stuck loading forever" gaps found by a
/// live E2E test (2026-08-11): the create/edit-organization dialogs only
/// caught PlatformAdminException, so any other exception left them spinning
/// forever with no reset and no message; and the existing-owner picker's
/// FutureBuilder only checked snapshot.hasData, so a failed fetch showed an
/// infinite spinner with no error or retry. A follow-up review then found
/// the fix's own error text was raw hardcoded Arabic (wrong under an
/// English locale) and exposed snapshot.error/error.toString() directly to
/// the user — this file proves both the original crash class AND that the
/// fix message is the real localized generic string, never the raw
/// exception text.
Response<dynamic> _envelope(
  String path,
  dynamic data, {
  Map<String, dynamic> meta = const <String, dynamic>{
    'current_page': 1,
    'last_page': 1,
    'per_page': 20,
    'total': 0,
  },
}) => Response<dynamic>(
  requestOptions: RequestOptions(path: path),
  statusCode: 200,
  data: <String, dynamic>{
    'success': true,
    'message': 'OK',
    'data': data,
    'meta': meta,
    'errors': null,
  },
);

Future<void> _openCreateOrganizationDialog(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.add_business_outlined));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'create-organization dialog resets loading and shows a localized generic message on an unexpected (non-HTTP) error, never the raw exception text',
    (tester) async {
      final client = FakeNetworkClient(
        getHandler: (path) async => _envelope(path, <dynamic>[]),
        postHandler: (path, data) async {
          if (path.contains('/admin/organizations')) {
            // A real delay so the test can observe the loading state before
            // it resolves — an instant rejection would settle within the
            // same microtask flush as the first pump(), racing past it.
            await Future<void>.delayed(const Duration(milliseconds: 50));
            // Not a DioException — the exact class of error the original
            // catch (on PlatformAdminException only) never handled.
            throw const FormatException(
              'unexpected response shape from server',
            );
          }
          return _envelope(path, <String, dynamic>{});
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            networkClientProvider.overrideWithValue(client),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: PlatformOrganizationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openCreateOrganizationDialog(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم المؤسسة'),
        'Test Org',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'اسم المالك'),
        'Owner Name',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'بريد المالك الإلكتروني'),
        'owner@example.com',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'كلمة مرور المالك (12 حرفاً على الأقل)',
        ),
        'a-long-enough-password',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'إنشاء المؤسسة'));
      await tester.pump();
      // Loading state must show immediately after tapping, before the
      // delayed rejection above resolves.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Reset — the button must be a real, re-enabled label again, not
      // stuck showing its spinner forever.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.widgetWithText(FilledButton, 'إنشاء المؤسسة'),
        findsOneWidget,
      );

      // The real, localized, generic message — never the raw
      // FormatException text leaking implementation detail to the user.
      expect(
        find.text('An unexpected error occurred. Please try again.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('unexpected response shape from server'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'existing-owner picker shows a localized error with retry after a failed fetch, and retry recovers',
    (tester) async {
      var userFetchAttempts = 0;
      const ownersJson = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 7,
          'name': 'Existing Owner',
          'email': 'existing@example.com',
          'is_active': true,
          'is_super_admin': false,
          'memberships': <dynamic>[],
          'created_at': '2026-01-01T00:00:00Z',
          'last_login_at': null,
        },
      ];

      final client = FakeNetworkClient(
        getHandler: (path) async {
          if (path.contains('/admin/users')) {
            userFetchAttempts++;
            if (userFetchAttempts == 1) {
              throw const FormatException('boom');
            }
            return _envelope(path, ownersJson);
          }
          return _envelope(path, <dynamic>[]);
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            networkClientProvider.overrideWithValue(client),
          ],
          child: const MaterialApp(
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: PlatformOrganizationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _openCreateOrganizationDialog(tester);

      // Switch to "existing owner" — the users future was already kicked
      // off in initState() regardless of this toggle, so its failure is
      // already resolved by the time this renders.
      await tester.tap(find.text('مالك موجود'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load the user list.'), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Retry'));
      await tester.pumpAndSettle();

      // Recovered to the real loaded state — error/retry gone, the picker
      // itself now rendered. Opening it proves the retried fetch's data
      // genuinely made it through, not just that the error view vanished.
      expect(find.text('Failed to load the user list.'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Retry'), findsNothing);
      expect(
        find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
        findsOneWidget,
      );
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Existing Owner — existing@example.com'),
        findsOneWidget,
      );
      expect(userFetchAttempts, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
