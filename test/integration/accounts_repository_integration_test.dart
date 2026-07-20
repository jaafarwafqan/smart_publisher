import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/backend_contracts/v1/accounts_contract_v1.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';
import 'package:smart_publisher/src/platforms/core/platform_factory.dart';

import '../helpers/fake_network_client.dart';

void main() {
  group('Integration - AccountRepositoryImpl', () {
    test(
      'loads six managed accounts and merges remote connection state',
      () async {
        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <dynamic>[
                    <String, dynamic>{
                      'id': 'facebook',
                      'name': 'Business Page',
                      'platform': 'facebook',
                      'connected': true,
                      'permissions': <String>['publish', 'schedule'],
                    },
                  ],
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final result = await repository.getAccounts();
        final accounts = result.data ?? const [];

        expect(accounts.length, 6);
        expect(
          accounts.any(
            (account) => account.platform == 'facebook' && account.isConnected,
          ),
          isTrue,
        );
        expect(
          accounts.any((account) => account.platform == 'twitter'),
          isTrue,
        );
      },
    );

    test(
      'connect sends oauth token lifecycle and permissions to Laravel',
      () async {
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              if (path.contains('/accounts/connect')) {
                sentPayload = (data as Map<String, dynamic>);
              }
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: const <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{},
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final accountsResult = await repository.getAccounts();
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'facebook',
        );

        final connectResult = await repository.connectAccount(account);

        expect(connectResult.isSuccess, isTrue);
        expect(sentPayload, isNotNull);
        expect(sentPayload!['platform'], 'facebook');
        expect(sentPayload!['access_token'], isNotNull);
        expect(sentPayload!['refresh_token'], isNotNull);
        expect(sentPayload!['expires_at'], isNotNull);
        expect(sentPayload!['permissions'], isA<List<dynamic>>());
        expect(
          (sentPayload!['permissions'] as List<dynamic>).isNotEmpty,
          isTrue,
        );

        final dto = ConnectAccountRequestDtoV1(
          platform: sentPayload!['platform'] as String,
          accessToken: sentPayload!['access_token'] as String,
          refreshToken: sentPayload!['refresh_token'] as String?,
          expiresAt: DateTime.tryParse(
            (sentPayload!['expires_at'] as String?) ?? '',
          ),
          permissions: (sentPayload!['permissions'] as List<dynamic>)
              .map((item) => item.toString())
              .toList(growable: false),
        );

        expect(dto.accessToken.isNotEmpty, isTrue);
        expect(dto.refreshToken, isNotNull);
        expect(dto.expiresAt, isNotNull);
        expect(dto.permissions.isNotEmpty, isTrue);
      },
    );
  });
}
