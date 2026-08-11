import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/platform_administration/presentation/screens/platform_admin_screens.dart';

import '../../helpers/fake_network_client.dart';

/// Regression coverage for the bug reported 2026-08-10: every
/// FutureBuilder-backed screen in platform_admin_screens.dart passed
/// `snapshot.data!` directly as a `content:` constructor argument to
/// `AppAsyncSwitcher` — Dart evaluates that eagerly on the very FIRST
/// build (while still loading, before `snapshot.data` exists), throwing
/// "Null check operator used on a null value" before the switcher ever
/// got to render its `loading` branch instead. A super_admin session hit
/// this on every screen it opened. These tests pump exactly ONE frame
/// (deliberately not `pumpAndSettle()`) so they land on that first,
/// previously-crashing loading-state build.
Response<dynamic> _envelope(String path, dynamic data) => Response<dynamic>(
  requestOptions: RequestOptions(path: path),
  statusCode: 200,
  data: data,
);

const _emptyPage = <String, dynamic>{
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
};

const _dashboardData = <String, dynamic>{
  'success': true,
  'message': 'OK',
  'data': <String, dynamic>{
    'statistics': <String, dynamic>{
      'organizations_total': 0,
      'organizations_active': 0,
      'organizations_inactive': 0,
      'users_total': 0,
      'users_last_30_days': 0,
      'organizations_without_active_owner': 0,
    },
    'latest_organizations': <dynamic>[],
    'latest_users': <dynamic>[],
  },
  'meta': <String, dynamic>{},
  'errors': null,
};

FakeNetworkClient _client() {
  return FakeNetworkClient(
    getHandler: (path) async => _envelope(
      path,
      path.contains('/admin/dashboard') ? _dashboardData : _emptyPage,
    ),
  );
}

void main() {
  group('platform_admin_screens loading-state rendering (no eager null unwrap)', () {
    testWidgets(
      'PlatformAdministrationScreen does not crash on its first (loading) frame',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              networkClientProvider.overrideWithValue(_client()),
            ],
            child: const MaterialApp(home: PlatformAdministrationScreen()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PlatformOrganizationsScreen does not crash on its first (loading) frame',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              networkClientProvider.overrideWithValue(_client()),
            ],
            child: const MaterialApp(home: PlatformOrganizationsScreen()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PlatformUsersScreen does not crash on its first (loading) frame',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              networkClientProvider.overrideWithValue(_client()),
            ],
            child: const MaterialApp(home: PlatformUsersScreen()),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'PlatformOrganizationDetailScreen does not crash on its first (loading) frame',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: <Override>[
              networkClientProvider.overrideWithValue(
                FakeNetworkClient(
                  getHandler: (path) async => _envelope(path, <String, dynamic>{
                    'success': true,
                    'message': 'OK',
                    'data': <String, dynamic>{
                      'organization': <String, dynamic>{
                        'id': 1,
                        'name': 'Org',
                        'status': 'active',
                        'members_count': 0,
                        'created_at': null,
                        'last_activity_at': null,
                      },
                      'members': <dynamic>[],
                      'social_accounts': <dynamic>[],
                      'posts_summary': <String, dynamic>{},
                    },
                    'meta': <String, dynamic>{},
                    'errors': null,
                  }),
                ),
              ),
            ],
            child: const MaterialApp(
              home: PlatformOrganizationDetailScreen(organizationId: 1),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
