import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/data/account_repository_impl.dart';

import '../helpers/fake_network_client.dart';

const _userId = 'user-1';

void main() {
  group('Integration - Facebook OAuth (AccountRepositoryImpl)', () {
    test(
      'beginFacebookOAuth posts provider/redirect_uri/scopes and returns the real authorize url',
      () async {
        String? sentPath;
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'message': 'OAuth authorization URL generated.',
                    'provider': 'facebook',
                    'state': 'abc123',
                    'state_expires_at': '2026-07-26T12:15:00Z',
                    'authorize_url':
                        'https://www.facebook.com/v20.0/dialog/oauth?client_id=1&redirect_uri=http://localhost:5055/&state=abc123',
                  },
                },
              );
            },
          ),
        );

        final result = await repository.beginFacebookOAuth(
          userId: _userId,
          redirectUri: 'http://localhost:5055/',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/social-accounts/authorize'));
        expect(sentPayload!['provider'], 'facebook');
        expect(sentPayload!['redirect_uri'], 'http://localhost:5055/');
        expect(sentPayload!['scopes'], <String>[
          'pages_show_list',
          'pages_read_engagement',
          'pages_manage_posts',
        ]);
        expect(result.data, contains('facebook.com'));
      },
    );

    test(
      'completeFacebookOAuth posts provider/code/state and maps the connected account',
      () async {
        String? sentPath;
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '42',
                    'provider': 'facebook',
                    'provider_account_id': 'fb-user-1',
                    'account_name': 'Jaafar',
                    'status': 'connected',
                    'discovery_mode': 'auto',
                  },
                },
              );
            },
          ),
        );

        final result = await repository.completeFacebookOAuth(
          userId: _userId,
          code: 'facebook-auth-code',
          state: 'abc123',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/social-accounts/callback'));
        expect(sentPayload!['provider'], 'facebook');
        expect(sentPayload!['code'], 'facebook-auth-code');
        expect(sentPayload!['state'], 'abc123');
        expect(result.data!.platform, 'facebook');
        expect(result.data!.remoteId, '42');
        expect(result.data!.discoveryMode, 'auto');
      },
    );
  });

  group('Integration - Facebook native sign-in (AccountRepositoryImpl)', () {
    /// Android/iOS only (flutter_facebook_auth) — distinct from
    /// beginFacebookOAuth/completeFacebookOAuth above, which stay the
    /// browser-redirect flow for web/desktop.
    test(
      'connectFacebookNative posts provider/access_token and maps the connected account',
      () async {
        String? sentPath;
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '99',
                    'provider': 'facebook',
                    'provider_account_id': 'fb-native-user-1',
                    'account_name': 'Native Login User',
                    'status': 'connected',
                    'discovery_mode': 'auto',
                  },
                },
              );
            },
          ),
        );

        final result = await repository.connectFacebookNative(
          userId: _userId,
          accessToken: 'sdk-issued-token',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/social-accounts/native-connect'));
        expect(sentPayload!['provider'], 'facebook');
        expect(sentPayload!['access_token'], 'sdk-issued-token');
        expect(result.data!.platform, 'facebook');
        expect(result.data!.remoteId, '99');
        expect(result.data!.discoveryMode, 'auto');
      },
    );

    test(
      'connectFacebookNative surfaces a failure when the backend rejects the token (e.g. wrong-app token)',
      () async {
        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 422,
                data: <String, dynamic>{
                  'success': false,
                  'message':
                      'Facebook rejected this sign-in: this access token was not issued for this application.',
                },
              );
            },
          ),
        );

        final result = await repository.connectFacebookNative(
          userId: _userId,
          accessToken: 'foreign-app-token',
        );

        expect(result.isSuccess, isFalse);
      },
    );
  });

  group('Integration - WhatsApp OAuth (AccountRepositoryImpl)', () {
    test(
      'beginWhatsAppOAuth posts provider=whatsapp and whatsapp-specific scopes',
      () async {
        String? sentPath;
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              sentPath = path;
              sentPayload = data as Map<String, dynamic>;
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'message': 'OAuth authorization URL generated.',
                    'provider': 'whatsapp',
                    'state': 'xyz789',
                    'authorize_url':
                        'https://www.facebook.com/v20.0/dialog/oauth?client_id=1&state=xyz789',
                  },
                },
              );
            },
          ),
        );

        final result = await repository.beginWhatsAppOAuth(
          userId: _userId,
          redirectUri: 'http://localhost:5055/',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/social-accounts/authorize'));
        expect(sentPayload!['provider'], 'whatsapp');
        expect(sentPayload!['scopes'], <String>[
          'whatsapp_business_messaging',
          'whatsapp_business_management',
        ]);
        expect(result.data, contains('facebook.com'));
      },
    );

    test(
      'completeWhatsAppOAuth maps the connected account without a business id yet',
      () async {
        final repository = AccountRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': '77',
                    'provider': 'whatsapp',
                    'provider_account_id': 'wa-user-1',
                    'account_name': 'Business Admin',
                    'status': 'connected',
                    'discovery_mode': 'auto',
                    'metadata': <String, dynamic>{},
                  },
                },
              );
            },
          ),
        );

        final result = await repository.completeWhatsAppOAuth(
          userId: _userId,
          code: 'whatsapp-auth-code',
          state: 'xyz789',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.remoteId, '77');
        expect(result.data!.hasWhatsAppBusinessId, isFalse);
      },
    );

    test(
      'setWhatsAppBusinessId PUTs merged metadata and returns the updated account',
      () async {
        String? sentPath;
        Map<String, dynamic>? sentPayload;

        final repository = AccountRepositoryImpl(
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
                    'id': '77',
                    'provider': 'whatsapp',
                    'provider_account_id': 'wa-user-1',
                    'status': 'connected',
                    'discovery_mode': 'auto',
                    'metadata': <String, dynamic>{'business_id': 'biz-1'},
                  },
                },
              );
            },
          ),
        );

        final result = await repository.setWhatsAppBusinessId(
          userId: _userId,
          socialAccountId: '77',
          businessId: 'biz-1',
        );

        expect(result.isSuccess, isTrue);
        expect(sentPath, contains('/social-accounts/77'));
        expect(sentPayload!['metadata']['business_id'], 'biz-1');
        expect(result.data!.hasWhatsAppBusinessId, isTrue);
      },
    );
  });
}
