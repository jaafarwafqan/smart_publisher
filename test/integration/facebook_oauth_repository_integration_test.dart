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
          'instagram_basic',
          'instagram_content_publish',
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

  // XOAuthProvider is real (see the backend), but 'x'/'twitter' stays
  // outside isBetaLaunchPlatform until a live publish is verified — these
  // repository methods are unreachable from the Connect UI today, same as
  // beginWhatsAppOAuth/completeWhatsAppOAuth were before WhatsApp's OAuth
  // was built. The PKCE code_verifier/code_challenge pair itself is
  // generated and cached server-side (see SocialAccountController on the
  // backend), so nothing PKCE-specific appears in this request/response
  // shape — it's a plain mirror of the Facebook/WhatsApp pairs above.
  group('Integration - X OAuth (AccountRepositoryImpl)', () {
    test('beginXOAuth posts provider=x and x-specific scopes', () async {
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
                  'provider': 'x',
                  'state': 'x-state-1',
                  'authorize_url':
                      'https://twitter.com/i/oauth2/authorize?client_id=1&state=x-state-1&code_challenge=abc',
                },
              },
            );
          },
        ),
      );

      final result = await repository.beginXOAuth(
        userId: _userId,
        redirectUri: 'http://localhost:5055/',
      );

      expect(result.isSuccess, isTrue);
      expect(sentPath, contains('/social-accounts/authorize'));
      expect(sentPayload!['provider'], 'x');
      expect(sentPayload!['scopes'], <String>[
        'tweet.read',
        'tweet.write',
        'users.read',
        'offline.access',
      ]);
      expect(result.data, contains('twitter.com'));
    });

    test(
      'completeXOAuth posts provider=x and maps the connected account to the local "twitter" platform id',
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
                    'id': '99',
                    'provider': 'x',
                    'provider_account_id': 'x-user-1',
                    'account_name': 'X Test Account',
                    'account_username': '@x_test_account',
                    'status': 'connected',
                    'discovery_mode': 'auto',
                    'metadata': <String, dynamic>{},
                  },
                },
              );
            },
          ),
        );

        final result = await repository.completeXOAuth(
          userId: _userId,
          code: 'x-auth-code',
          state: 'x-state-1',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.remoteId, '99');
        // _platformFromBackendProvider maps the backend's 'x' to this
        // app's locally-seeded 'twitter' placeholder id.
        expect(result.data!.platform, 'twitter');
      },
    );
  });
}
