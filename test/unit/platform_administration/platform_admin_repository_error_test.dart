import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/platform_administration/data/platform_admin_repository.dart';

import '../../helpers/fake_network_client.dart';

/// Regression test for the exact bug reported 2026-08-10: the "Create
/// organization" dialog showed only the generic "Validation failed" text
/// (untranslated and useless — e.g. it never revealed that the new owner's
/// password was missing a symbol), because PlatformAdminException only
/// ever read the envelope's top-level `message`, discarding `errors`.
void main() {
  group('PlatformAdminRepository error handling', () {
    test(
      'createOrganization surfaces the real field-specific validation reason, not the generic wrapper',
      () async {
        final repository = PlatformAdminRepository(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              throw DioException(
                requestOptions: RequestOptions(path: path),
                response: Response<dynamic>(
                  requestOptions: RequestOptions(path: path),
                  statusCode: 422,
                  data: <String, dynamic>{
                    'success': false,
                    'message': 'Validation failed',
                    'errors': <String, dynamic>{
                      'new_owner.password': <String>[
                        'The new owner.password field must contain at least one symbol.',
                      ],
                    },
                  },
                ),
                type: DioExceptionType.badResponse,
              );
            },
          ),
        );

        await expectLater(
          repository.createOrganization(
            name: 'التمريض',
            newOwnerName: 'بهاء',
            newOwnerEmail: 'baia@uokafa.edu.iq',
            newOwnerPassword: 'weakpassword',
          ),
          throwsA(
            isA<PlatformAdminException>().having(
              (e) => e.message,
              'message',
              'The new owner.password field must contain at least one symbol.',
            ),
          ),
        );
      },
    );

    test('a non-validation error still shows the top-level message', () async {
      final repository = PlatformAdminRepository(
        networkClient: FakeNetworkClient(
          postHandler: (path, data) async {
            throw DioException(
              requestOptions: RequestOptions(path: path),
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 403,
                data: <String, dynamic>{
                  'success': false,
                  'message': 'This action is unauthorized.',
                  'errors': <String, dynamic>{
                    'code': <String>['unauthorized'],
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            );
          },
        ),
      );

      await expectLater(
        repository.createOrganization(name: 'Org'),
        throwsA(
          isA<PlatformAdminException>().having(
            (e) => e.message,
            'message',
            'This action is unauthorized.',
          ),
        ),
      );
    });
  });
}
