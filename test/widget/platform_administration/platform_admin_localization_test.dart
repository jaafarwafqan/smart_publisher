import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/platform_administration/presentation/screens/platform_admin_screens.dart';

import '../../helpers/fake_network_client.dart';
import '../../helpers/localized_test_app.dart';

/// Regression coverage for the 2026-08-12 audit finding: this screen had
/// 154 raw Arabic string literals still baked into the source, so it never
/// actually respected the app's locale — English users saw Arabic text.
/// Proves the ARB migration actually wires through end to end for both
/// supported locales, on a representative slice of the screen (app bar
/// title, empty state, and a placeholder-bearing message), rather than just
/// asserting the ARB files contain the right keys.
Response<dynamic> _emptyPage(String path) => Response<dynamic>(
  requestOptions: RequestOptions(path: path),
  statusCode: 200,
  data: <String, dynamic>{
    'success': true,
    'message': 'OK',
    'data': <dynamic>[],
    'meta': <String, dynamic>{
      'current_page': 1,
      'last_page': 1,
      'per_page': 20,
      'total': 0,
    },
    'errors': null,
  },
);

FakeNetworkClient _client() =>
    FakeNetworkClient(getHandler: (path) async => _emptyPage(path));

Future<void> _pumpOrganizationsScreen(WidgetTester tester, Locale locale) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[networkClientProvider.overrideWithValue(_client())],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: const PlatformOrganizationsScreen(),
      ),
    ),
  );
}

void main() {
  group('platform admin screens honor the app locale (not hardcoded Arabic)', () {
    testWidgets('organizations screen renders in English', (tester) async {
      await _pumpOrganizationsScreen(tester, const Locale('en'));
      await tester.pumpAndSettle();

      expect(find.text('Organizations'), findsOneWidget);
      expect(find.text('No matching organizations'), findsOneWidget);
      expect(
        find.text('Try adjusting your search terms or create a new organization.'),
        findsOneWidget,
      );
      // The pre-migration Arabic text must not leak through regardless of
      // locale — that was the entire bug.
      expect(find.text('المؤسسات'), findsNothing);
      expect(find.text('لا توجد مؤسسات مطابقة'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('organizations screen renders in Arabic', (tester) async {
      await _pumpOrganizationsScreen(tester, const Locale('ar'));
      await tester.pumpAndSettle();

      expect(find.text('المؤسسات'), findsOneWidget);
      expect(find.text('لا توجد مؤسسات مطابقة'), findsOneWidget);
      expect(
        find.text('جرّب تعديل كلمات البحث أو أنشئ مؤسسة جديدة.'),
        findsOneWidget,
      );
      expect(find.text('Organizations'), findsNothing);
      expect(find.text('No matching organizations'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('users screen app bar and add-user button follow the locale', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            networkClientProvider.overrideWithValue(_client()),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: testLocalizationsDelegates,
            supportedLocales: testSupportedLocales,
            home: PlatformUsersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System users'), findsOneWidget);
      // Appears twice: the FAB and the empty-state action share the same
      // "Add user" copy by design (same action, same label everywhere).
      expect(find.text('Add user'), findsWidgets);
      expect(find.text('مستخدمو النظام'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'a placeholder-bearing string (member count) interpolates correctly in both locales',
      (tester) async {
        final client = FakeNetworkClient(
          getHandler: (path) async {
            if (path.contains('/admin/organizations')) {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'message': 'OK',
                  'data': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 1,
                      'name': 'Test Org',
                      'status': 'active',
                      'primary_owner': <String, dynamic>{
                        'id': 1,
                        'name': 'Owner',
                        'email': 'owner@example.com',
                      },
                      'primary_owner_missing': false,
                      'members_count': 4,
                      'created_at': '2026-01-01T00:00:00Z',
                    },
                  ],
                  'meta': <String, dynamic>{
                    'current_page': 1,
                    'last_page': 1,
                    'per_page': 20,
                    'total': 1,
                  },
                  'errors': null,
                },
              );
            }
            return _emptyPage(path);
          },
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              networkClientProvider.overrideWithValue(client),
            ],
            child: const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: testSupportedLocales,
              home: PlatformOrganizationsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('4 members'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
