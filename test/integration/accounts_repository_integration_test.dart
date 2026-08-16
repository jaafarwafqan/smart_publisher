import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';
import 'package:smart_publisher/src/features/auth/domain/entities/account_entity.dart';

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
      // Sprint I (role/permission remediation, 2026-08-09): connectAccount()
      // used to fall back to a locally-generated mock token posted to a
      // manual "store" endpoint (SocialAccountController::store()); that
      // endpoint was removed from the backend once Sprint C confirmed every
      // real UI path always resolves to a dedicated flow first
      // (connectTelegramBot / beginFacebookOAuth+completeFacebookOAuth /
      // beginWhatsAppOAuth+completeWhatsAppOAuth). This asserts the honest
      // failure that replaced the fake-success path, and that no network
      // call is made at all.
      'connectAccount fails without a network call — every real platform has its own dedicated connect flow',
      () async {
        var postCalled = false;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              postCalled = true;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 201,
                data: const <String, dynamic>{},
              );
            },
          ),
        );

        final accountsResult = await repository.getAccounts(userId: _userId);
        final account = (accountsResult.data ?? const []).firstWhere(
          (a) => a.platform == 'facebook',
        );

        final connectResult = await repository.connectAccount(
          account,
          userId: _userId,
        );

        expect(connectResult.isFailure, isTrue);
        expect(postCalled, isFalse);
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
      // 2026-08: the Instagram placeholder used to stay AccountStatus.disconnected
      // forever, even after a real, live-verified Instagram publish —
      // _mergeRemoteAccounts() only ever updates the 'facebook' entry
      // since an instagram_business page's SocialAccountResponseDtoV1 still
      // carries provider 'facebook' (Instagram has no OAuth of its own).
      'derives the Instagram card\'s connected status from a linked instagram_business page under the Facebook account',
      () async {
        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async {
              if (path.contains('/pages')) {
                return Response<dynamic>(
                  requestOptions: RequestOptions(path: path),
                  statusCode: 200,
                  data: <String, dynamic>{
                    'success': true,
                    'data': <dynamic>[
                      <String, dynamic>{
                        'id': '1',
                        'social_account_id': '42',
                        'page_id': 'fb-page-1',
                        'kind': 'page',
                        'name': 'Business Page',
                        'can_publish': true,
                        'is_selected': true,
                        'status': 'valid',
                      },
                      <String, dynamic>{
                        'id': '2',
                        'social_account_id': '42',
                        'page_id': 'ig-1',
                        'kind': 'instagram_business',
                        'name': 'qolob_tantather_alnoor',
                        'picture_url': 'https://example.com/ig.jpg',
                        'can_publish': true,
                        'is_selected': true,
                        'status': 'valid',
                      },
                    ],
                  },
                );
              }

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
                      'discovery_mode': 'auto',
                    },
                  ],
                },
              );
            },
          ),
        );

        final result = await repository.getAccounts(userId: _userId);
        final accounts = result.data ?? const [];
        final instagram = accounts.firstWhere(
          (account) => account.platform == 'instagram',
        );

        expect(instagram.isConnected, isTrue);
        expect(instagram.name, 'qolob_tantather_alnoor');
        expect(instagram.avatarUrl, 'https://example.com/ig.jpg');
        // Deliberately not attached — page selection/sync stays a single
        // source of truth under the Facebook card, see
        // AccountRepositoryImpl._deriveInstagramStatusFromFacebookPages()'s
        // own docblock for why.
        expect(instagram.remoteId, isNull);
        expect(instagram.pages, isEmpty);
      },
    );

    test(
      'the Instagram card stays disconnected when the Facebook account has no linked Instagram Business page',
      () async {
        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async {
              if (path.contains('/pages')) {
                return Response<dynamic>(
                  requestOptions: RequestOptions(path: path),
                  statusCode: 200,
                  data: <String, dynamic>{
                    'success': true,
                    'data': <dynamic>[
                      <String, dynamic>{
                        'id': '1',
                        'social_account_id': '42',
                        'page_id': 'fb-page-1',
                        'kind': 'page',
                        'name': 'Business Page',
                        'can_publish': true,
                        'status': 'valid',
                      },
                    ],
                  },
                );
              }

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
                      'discovery_mode': 'auto',
                    },
                  ],
                },
              );
            },
          ),
        );

        final result = await repository.getAccounts(userId: _userId);
        final instagram = (result.data ?? const []).firstWhere(
          (account) => account.platform == 'instagram',
        );

        expect(instagram.isConnected, isFalse);
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
