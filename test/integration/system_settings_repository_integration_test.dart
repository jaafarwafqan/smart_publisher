import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/administration/data/system_settings_repository_impl.dart';

import '../helpers/fake_network_client.dart';

void main() {
  group('Integration - SystemSettingsRepositoryImpl', () {
    test('getOAuthProviderSettings parses the provider list', () async {
      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'provider': 'facebook',
                    'client_id': 'fb-client-id',
                    'has_client_secret': true,
                    'is_enabled': true,
                  },
                  <String, dynamic>{
                    'provider': 'linkedin',
                    'client_id': null,
                    'has_client_secret': false,
                    'is_enabled': true,
                  },
                ],
              },
            );
          },
        ),
      );

      final result = await repository.getOAuthProviderSettings();

      expect(result.isSuccess, isTrue);
      expect(result.data!.length, 2);
      final facebook = result.data!.firstWhere((p) => p.provider == 'facebook');
      expect(facebook.isConfigured, isTrue);
      final linkedin = result.data!.firstWhere((p) => p.provider == 'linkedin');
      expect(linkedin.isConfigured, isFalse);
    });

    test(
      'updateOAuthProviderSetting omits client_secret entirely when left blank',
      () async {
        String? sentPath;
        Map<String, dynamic>? sentPayload;

        final repository = SystemSettingsRepositoryImpl(
          networkClient: FakeNetworkClient(
            putHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'provider': 'linkedin',
                    'client_id': 'li-client-id-updated',
                    'has_client_secret': true,
                    'is_enabled': true,
                  },
                },
              );
            },
          ),
        );

        final result = await repository.updateOAuthProviderSetting(
          'linkedin',
          clientId: 'li-client-id-updated',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/admin/oauth-providers/linkedin'));
        expect(sentPayload!['client_id'], 'li-client-id-updated');
        expect(sentPayload!.containsKey('client_secret'), isFalse);
        expect(result.data!.clientId, 'li-client-id-updated');
      },
    );

    test(
      'updateOAuthProviderSetting includes client_secret when provided',
      () async {
        Map<String, dynamic>? sentPayload;

        final repository = SystemSettingsRepositoryImpl(
          networkClient: FakeNetworkClient(
            putHandler: (path, data) async {
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'provider': 'linkedin',
                    'client_id': 'li-id',
                    'has_client_secret': true,
                    'is_enabled': true,
                  },
                },
              );
            },
          ),
        );

        await repository.updateOAuthProviderSetting(
          'linkedin',
          clientId: 'li-id',
          clientSecret: 'li-secret',
        );

        expect(sentPayload!['client_secret'], 'li-secret');
      },
    );

    test(
      'testConnection posts to the provider test endpoint and parses the result',
      () async {
        String? sentPath;

        final repository = SystemSettingsRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'success': true,
                    'message': 'Facebook credentials verified successfully.',
                    'tested_at': '2026-07-26T10:32:00Z',
                  },
                },
              );
            },
          ),
        );

        final result = await repository.testConnection('facebook');

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/admin/oauth-providers/facebook/test'));
        expect(result.data!.success, isTrue);
        expect(
          result.data!.message,
          'Facebook credentials verified successfully.',
        );
        expect(result.data!.testedAt, isNotNull);
      },
    );

    test(
      'testConnection surfaces a failed verification without treating it as a repository error',
      () async {
        final repository = SystemSettingsRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'success': false,
                    'message': 'Invalid client_secret.',
                  },
                },
              );
            },
          ),
        );

        final result = await repository.testConnection('facebook');

        expect(result.isSuccess, isTrue);
        expect(result.data!.success, isFalse);
        expect(result.data!.message, 'Invalid client_secret.');
      },
    );

    test('getAuditLog parses recent entries', () async {
      String? sentPath;

      final repository = SystemSettingsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            sentPath = path;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'action': 'updated',
                    'changed_fields': <String>['client_id', 'client_secret'],
                    'success': null,
                    'user_name': 'Admin User',
                    'created_at': '2026-07-26T10:00:00Z',
                  },
                  <String, dynamic>{
                    'action': 'tested',
                    'changed_fields': <String>[],
                    'success': true,
                    'user_name': 'Admin User',
                    'created_at': '2026-07-26T10:32:00Z',
                  },
                ],
              },
            );
          },
        ),
      );

      final result = await repository.getAuditLog('facebook');

      expect(result.isSuccess, isTrue);
      expect(sentPath, contains('/admin/oauth-providers/facebook/audit-log'));
      expect(result.data!.length, 2);
      expect(result.data!.first.action, 'updated');
      expect(result.data!.first.changedFields, ['client_id', 'client_secret']);
      expect(result.data!.last.success, isTrue);
    });
  });
}
