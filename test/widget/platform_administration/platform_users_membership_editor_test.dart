import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/features/platform_administration/presentation/screens/platform_admin_screens.dart';

import '../../helpers/fake_network_client.dart';

/// Regression coverage for the bug reported 2026-08-11: the "إدارة
/// العضويات" (manage memberships) dialog's "إضافة إلى مؤسسة" dropdown is a
/// [DropdownButtonFormField] whose internal FormFieldState retains its
/// selected organization across rebuilds — but picking an organization
/// immediately filters that same organization OUT of the dropdown's own
/// `items` list (it's now already a membership), leaving the retained
/// value matching zero items and tripping Flutter's "exactly one item
/// must match value" assertion on every subsequent build. Reproduced here
/// end-to-end through the real screen and real dialog (not a synthetic
/// widget), using live-shaped API JSON, matching this session's established
/// reproduce-first methodology for "crash reported but cause unclear" bugs.
Response<dynamic> _envelope(
  String path,
  dynamic data, {
  Map<String, dynamic> meta = const <String, dynamic>{
    'current_page': 1,
    'last_page': 1,
    'per_page': 20,
    'total': 1,
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

const _organizationsJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 1,
    'name': 'جامعة الكفيل',
    'status': 'active',
    'members_count': 3,
    'created_at': '2026-01-01T00:00:00Z',
  },
  <String, dynamic>{
    'id': 2,
    'name': 'جامعة بغداد',
    'status': 'active',
    'members_count': 2,
    'created_at': '2026-01-01T00:00:00Z',
  },
  <String, dynamic>{
    'id': 3,
    'name': 'جامعة البصرة',
    'status': 'active',
    'members_count': 1,
    'created_at': '2026-01-01T00:00:00Z',
  },
];

const _usersJson = <Map<String, dynamic>>[
  <String, dynamic>{
    'id': 42,
    'name': 'jaafar',
    'email': 'jaafar@example.com',
    'is_active': true,
    'is_super_admin': false,
    'memberships': <dynamic>[],
    'created_at': '2026-01-01T00:00:00Z',
    'last_login_at': null,
  },
];

FakeNetworkClient _client() {
  return FakeNetworkClient(
    getHandler: (path) async {
      if (path.contains('/admin/organizations')) {
        return _envelope(
          path,
          _organizationsJson,
          meta: const <String, dynamic>{
            'current_page': 1,
            'last_page': 1,
            'per_page': 100,
            'total': 3,
          },
        );
      }
      if (path.contains('/admin/users')) {
        return _envelope(path, _usersJson);
      }
      return _envelope(path, <dynamic>[]);
    },
    putHandler: (path, data) async => _envelope(path, <String, dynamic>{}),
  );
}

void main() {
  testWidgets(
    'picking an organization to add does not crash the dropdown on rebuild',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            networkClientProvider.overrideWithValue(_client()),
          ],
          child: const MaterialApp(home: PlatformUsersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Open the per-user actions menu and choose "إدارة العضويات".
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إدارة العضويات'));
      await tester.pumpAndSettle();

      expect(find.text('عضويات jaafar'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Pick the first organization from "إضافة إلى مؤسسة" — this is the
      // exact action from the bug report's screenshot.
      await tester.tap(find.text('إضافة إلى مؤسسة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جامعة الكفيل').last);
      await tester.pumpAndSettle();

      // The crash fired on this very rebuild in the reported bug — the
      // dropdown's retained value no longer matched any of its (now
      // filtered) items.
      expect(tester.takeException(), isNull);
      expect(find.text('جامعة الكفيل'), findsWidgets);

      // The dropdown must still be usable afterwards — pick a second
      // organization to prove the reset didn't just avoid the crash by
      // leaving the field permanently broken.
      await tester.tap(find.text('إضافة إلى مؤسسة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('جامعة بغداد').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('جامعة بغداد'), findsWidgets);

      // Saving must also succeed end to end.
      await tester.tap(find.text('حفظ العضويات'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
