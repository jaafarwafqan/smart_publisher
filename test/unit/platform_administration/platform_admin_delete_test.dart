import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/platform_administration/data/platform_admin_repository.dart';

import '../../helpers/fake_network_client.dart';

/// 2026-08: platform-admin delete for organizations (soft, backend-gated
/// on the organization already being inactive) and users (hard).
void main() {
  group('PlatformAdminRepository.deleteOrganization', () {
    test('DELETEs the real organization endpoint', () async {
      String? deletedPath;
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          deleteHandler: (path, data) async {
            deletedPath = path;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'message': 'Organization deleted.',
              },
            );
          },
        ),
      );

      await repository.deleteOrganization(7);

      expect(deletedPath, contains('/admin/organizations/7'));
    });

    test(
      'surfaces the backend\'s real rejection reason for a still-active organization',
      () async {
        final repository = PlatformAdminRepository(
          networkClient: FakeNetworkClient(
            deleteHandler: (path, data) async {
              throw DioException(
                requestOptions: RequestOptions(path: path),
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: path),
                  statusCode: 422,
                  // abort(422, $message) — Laravel's default HttpException
                  // JSON shape, no field-keyed `errors` map (unlike a real
                  // FormRequest validation failure).
                  data: <String, dynamic>{
                    'message':
                        'An organization must be deactivated before it can be deleted.',
                  },
                ),
                type: DioExceptionType.badResponse,
              );
            },
          ),
        );

        await expectLater(
          repository.deleteOrganization(7),
          throwsA(
            isA<PlatformAdminException>().having(
              (e) => e.message,
              'message',
              'An organization must be deactivated before it can be deleted.',
            ),
          ),
        );
      },
    );
  });

  group('PlatformAdminRepository.deleteUser', () {
    test('DELETEs the real user endpoint', () async {
      String? deletedPath;
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          deleteHandler: (path, data) async {
            deletedPath = path;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'message': 'User deleted.',
              },
            );
          },
        ),
      );

      await repository.deleteUser(42);

      expect(deletedPath, contains('/admin/users/42'));
    });

    test(
      'surfaces the backend\'s real rejection reason for a self-deletion',
      () async {
        final repository = PlatformAdminRepository(
          networkClient: FakeNetworkClient(
            deleteHandler: (path, data) async {
              throw DioException(
                requestOptions: RequestOptions(path: path),
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: path),
                  statusCode: 422,
                  // abort(422, $message) — no field-keyed `errors` map.
                  data: <String, dynamic>{
                    'message': 'You cannot delete your own account.',
                  },
                ),
                type: DioExceptionType.badResponse,
              );
            },
          ),
        );

        await expectLater(
          repository.deleteUser(1),
          throwsA(
            isA<PlatformAdminException>().having(
              (e) => e.message,
              'message',
              'You cannot delete your own account.',
            ),
          ),
        );
      },
    );
  });
}
