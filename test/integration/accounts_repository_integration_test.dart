import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/account_entity.dart';
import 'package:smart_publisher/src/platforms/core/platform_factory.dart';

import '../helpers/fake_network_client.dart';

const _userId = 'user-1';

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
                      'id': '42',
                      'provider': 'facebook',
                      'provider_account_id': 'fb-acc-1',
                      'account_name': 'Business Page',
                      'status': 'connected',
                      'has_refresh_token': true,
                      'scopes': <String>['publish', 'schedule'],
                    },
                  ],
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final result = await repository.getAccounts(userId: _userId);
        final accounts = result.data ?? const [];

        expect(accounts.length, 6);
        final facebook = accounts.firstWhere(
          (account) => account.platform == 'facebook',
        );
        expect(facebook.isConnected, isTrue);
        // Regression guard for the bug found during planning: the real
        // backend id ('42') must be captured as remoteId, not silently kept
        // as the local platform-string placeholder ('facebook').
        expect(facebook.remoteId, '42');
        expect(facebook.hasRefreshToken, isTrue);
        expect(
          accounts.any((account) => account.platform == 'twitter'),
          isTrue,
        );
      },
    );

    test(
      'connect sends oauth token lifecycle and scopes to the social-accounts endpoint',
      () async {
        Map<String, dynamic>? sentPayload;
        String? sentPath;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 201,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '99',
                    'provider': 'facebook',
                    'provider_account_id': sentPayload!['provider_account_id'],
                    'account_name': 'Business Page',
                    'status': 'connected',
                    'has_refresh_token': true,
                    'scopes': <String>['publish', 'schedule'],
                  },
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final accountsResult = await repository.getAccounts(userId: _userId);
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'facebook',
        );

        final connectResult = await repository.connectAccount(
          account,
          userId: _userId,
        );

        expect(connectResult.isSuccess, isTrue);
        expect(sentPath, contains('/users/$_userId/social-accounts'));
        expect(sentPayload, isNotNull);
        expect(sentPayload!['provider'], 'facebook');
        expect(sentPayload!['access_token'], isNotNull);
        expect(sentPayload!['refresh_token'], isNotNull);
        expect(sentPayload!['token_expires_at'], isNotNull);
        expect(sentPayload!['scopes'], isA<List<dynamic>>());
        expect((sentPayload!['scopes'] as List<dynamic>).isNotEmpty, isTrue);
        expect(connectResult.data!.remoteId, '99');
      },
    );

    test(
      'connecting the X account sends provider "x" to the backend, not the internal "twitter" key '
      '(regression: SocialAccountController only recognizes "x")',
      () async {
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 201,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '77',
                    'provider': 'x',
                    'provider_account_id': sentPayload!['provider_account_id'],
                    'account_name': 'X',
                    'status': 'connected',
                    'has_refresh_token': true,
                  },
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final accountsResult = await repository.getAccounts(userId: _userId);
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'twitter',
        );

        final connectResult = await repository.connectAccount(
          account,
          userId: _userId,
        );

        expect(sentPayload!['provider'], 'x');
        expect(connectResult.isSuccess, isTrue);
        // The response's platform ("x") must map back to this app's
        // internal "twitter" key, or a subsequent getAccounts() would treat
        // it as a brand new, unmatched platform instead of merging into the
        // existing local card.
        expect(connectResult.data!.platform, 'twitter');
      },
    );

    test(
      'disconnect deletes by the real remote id, not the local platform key',
      () async {
        String? deletedPath;

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
                      'id': '7',
                      'provider': 'facebook',
                      'provider_account_id': 'fb-acc-1',
                      'account_name': 'Business Page',
                      'status': 'connected',
                    },
                  ],
                },
              );
            },
            deleteHandler: (path, data) async {
              deletedPath = path;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'message': 'Social account removed successfully.',
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final accountsResult = await repository.getAccounts(userId: _userId);
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'facebook',
        );
        expect(account.remoteId, '7');

        final disconnectResult = await repository.disconnectAccount(
          account,
          userId: _userId,
        );

        expect(disconnectResult.isSuccess, isTrue);
        expect(deletedPath, '/users/$_userId/social-accounts/7');
      },
    );

    test(
      'refreshToken posts to the refresh-token endpoint using the remote id',
      () async {
        String? postedPath;

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
                      'id': '11',
                      'provider': 'facebook',
                      'provider_account_id': 'fb-acc-1',
                      'account_name': 'Business Page',
                      'status': 'expired',
                      'has_refresh_token': true,
                    },
                  ],
                },
              );
            },
            postHandler: (path, data) async {
              postedPath = path;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '11',
                    'provider': 'facebook',
                    'provider_account_id': 'fb-acc-1',
                    'account_name': 'Business Page',
                    'status': 'pending',
                    'has_refresh_token': true,
                  },
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final accountsResult = await repository.getAccounts(userId: _userId);
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'facebook',
        );

        final result = await repository.refreshToken(account, userId: _userId);

        expect(result.isSuccess, isTrue);
        expect(postedPath, '/users/$_userId/social-accounts/11/refresh-token');
        expect(result.data!.status, AccountStatus.pending);
      },
    );

    test(
      'refreshToken fails fast without a network call when no refresh token is available',
      () async {
        var postCalled = false;

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
                      'id': '12',
                      'provider': 'facebook',
                      'provider_account_id': 'fb-acc-1',
                      'account_name': 'Business Page',
                      'status': 'connected',
                      'has_refresh_token': false,
                    },
                  ],
                },
              );
            },
            postHandler: (path, data) async {
              postCalled = true;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: const <String, dynamic>{},
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final accountsResult = await repository.getAccounts(userId: _userId);
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'facebook',
        );

        final result = await repository.refreshToken(account, userId: _userId);

        expect(result.isFailure, isTrue);
        expect(postCalled, isFalse);
      },
    );

    test(
      'testConnection posts to the test endpoint and parses the health result',
      () async {
        String? postedPath;

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
                      'id': '13',
                      'provider': 'facebook',
                      'provider_account_id': 'fb-acc-1',
                      'account_name': 'Business Page',
                      'status': 'connected',
                    },
                  ],
                },
              );
            },
            postHandler: (path, data) async {
              postedPath = path;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'available': true,
                    'healthy': true,
                    'message': 'Connection is healthy.',
                  },
                },
              );
            },
          ),
          platformFactory: PlatformFactory(),
        );

        final accountsResult = await repository.getAccounts(userId: _userId);
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'facebook',
        );

        final result = await repository.testConnection(
          account,
          userId: _userId,
        );

        expect(result.isSuccess, isTrue);
        expect(postedPath, '/users/$_userId/social-accounts/13/test');
        expect(result.data!.available, isTrue);
        expect(result.data!.healthy, isTrue);
        expect(result.data!.message, 'Connection is healthy.');
      },
    );
  });
}
