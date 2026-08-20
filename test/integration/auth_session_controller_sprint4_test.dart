import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';

import '../helpers/fake_network_client.dart';

AuthSessionController _controllerWith(FakeNetworkClient client) {
  final tokenStorage = EncryptedTokenStorage(
    secretsManager: InMemorySecretsManager(),
  );
  return AuthSessionController(
    networkClient: client,
    tokenLifecycleManager: TokenLifecycleManager(tokenStorage: tokenStorage),
    storageService: InMemoryStorageService(),
    authEventPublisher: AuthEventPublisher(
      app_events.EventDispatcher(EventBus()),
    ),
  );
}

Response<dynamic> _envelope(String path, dynamic data, {int statusCode = 200}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  group('Integration - AuthSessionController Sprint 4 (Commercial SaaS)', () {
    test('register persists a session exactly like login does', () async {
      final client = FakeNetworkClient(
        postHandler: (path, data) async {
          expect(path, '/auth/register');
          expect(data, <String, dynamic>{
            'name': 'New Publisher',
            'email': 'new@example.com',
            'password': 'password123',
            'password_confirmation': 'password123',
          });
          return _envelope(path, <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'access_token': 'access-reg',
              'refresh_token': 'refresh-reg',
              'expires_in': 3600,
              'scope': 'posts.read',
              'user': <String, dynamic>{
                'id': 'user-9',
                'name': 'New Publisher',
                'email': 'new@example.com',
                'role': 'publisher',
              },
            },
          });
        },
      );

      final controller = _controllerWith(client);
      final session = await controller.register(
        name: 'New Publisher',
        email: 'new@example.com',
        password: 'password123',
        passwordConfirmation: 'password123',
      );

      expect(session.user.email, 'new@example.com');
      expect(await controller.currentSession(), isNotNull);
    });

    test(
      'login returns LoginRequiresTwoFactor without persisting a session',
      () async {
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'message': 'Two-factor authentication code required.',
                'two_factor_required': true,
                'challenge_token': 'challenge-abc',
              },
            });
          },
        );

        final controller = _controllerWith(client);
        final outcome = await controller.login(
          email: 'twofa@example.com',
          password: 'password123',
        );

        expect(outcome, isA<LoginRequiresTwoFactor>());
        expect(
          (outcome as LoginRequiresTwoFactor).challengeToken,
          'challenge-abc',
        );
        expect(await controller.currentSession(), isNull);
      },
    );

    test('completeTwoFactorChallenge persists a session on success', () async {
      final client = FakeNetworkClient(
        postHandler: (path, data) async {
          expect(path, '/auth/two-factor/challenge');
          expect(data, <String, dynamic>{
            'challenge_token': 'challenge-abc',
            'code': '123456',
          });
          return _envelope(path, <String, dynamic>{
            'success': true,
            'data': <String, dynamic>{
              'access_token': 'access-2fa',
              'refresh_token': 'refresh-2fa',
              'expires_in': 3600,
              'scope': 'posts.read',
              'user': <String, dynamic>{
                'id': 'user-9',
                'name': 'Two Factor User',
                'email': 'twofa@example.com',
                'role': 'publisher',
              },
            },
          });
        },
      );

      final controller = _controllerWith(client);
      final session = await controller.completeTwoFactorChallenge(
        challengeToken: 'challenge-abc',
        code: '123456',
      );

      expect(session.user.email, 'twofa@example.com');
      expect(await controller.currentSession(), isNotNull);
    });

    test(
      'completeTwoFactorChallenge surfaces an invalid-code failure',
      () async {
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            throw DioException(
              requestOptions: RequestOptions(path: path),
              response: Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 401,
                data: <String, dynamic>{
                  'success': false,
                  'message': 'Invalid authentication code.',
                  'errors': 'Invalid authentication code.',
                },
              ),
            );
          },
        );

        final controller = _controllerWith(client);

        await expectLater(
          controller.completeTwoFactorChallenge(
            challengeToken: 'challenge-abc',
            code: '000000',
          ),
          throwsA(
            isA<AuthSessionException>().having(
              (e) => e.message,
              'message',
              'Invalid authentication code.',
            ),
          ),
        );
      },
    );

    test(
      'forgotPassword and resetPassword complete without throwing on success',
      () async {
        final requestedPaths = <String>[];
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            requestedPaths.add(path);
            return _envelope(path, <String, dynamic>{
              'success': true,
              'message': 'OK',
              'data': <String, dynamic>{'message': 'OK'},
            });
          },
        );

        final controller = _controllerWith(client);

        await controller.forgotPassword(email: 'someone@example.com');
        await controller.resetPassword(
          email: 'someone@example.com',
          token: 'reset-token',
          password: 'newpassword123',
          passwordConfirmation: 'newpassword123',
        );

        expect(requestedPaths, <String>[
          '/auth/forgot-password',
          '/auth/reset-password',
        ]);
      },
    );

    test(
      'fetchCurrentUserStatus reads /me and extracts 2FA/verification flags',
      () async {
        final client = FakeNetworkClient(
          getHandler: (path) async {
            expect(path, '/me');
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'user': <String, dynamic>{
                  'two_factor_enabled': true,
                  'email_verified': false,
                },
              },
            });
          },
        );

        final controller = _controllerWith(client);
        final status = await controller.fetchCurrentUserStatus();

        expect(status.twoFactorEnabled, isTrue);
        expect(status.emailVerified, isFalse);
      },
    );

    test(
      'exportMyData reads GET /account/data-export and counts each section',
      () async {
        final client = FakeNetworkClient(
          getHandler: (path) async {
            expect(path, '/account/data-export');
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'user': <String, dynamic>{
                  'name': 'Ada Lovelace',
                  'email': 'ada@example.com',
                  'two_factor_enabled': true,
                  'email_verified_at': '2026-08-01T00:00:00+00:00',
                },
                'organizations': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 1},
                ],
                'posts': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 1},
                  <String, dynamic>{'id': 2},
                ],
                'social_accounts': <Map<String, dynamic>>[],
                'media_attachments': <Map<String, dynamic>>[
                  <String, dynamic>{'id': 1},
                ],
                'exported_at': '2026-08-08T12:00:00+00:00',
              },
            });
          },
        );

        final controller = _controllerWith(client);
        final export = await controller.exportMyData();

        expect(export.userEmail, 'ada@example.com');
        expect(export.organizationsCount, 1);
        expect(export.postsCount, 2);
        expect(export.socialAccountsCount, 0);
        expect(export.mediaAttachmentsCount, 1);
        expect(export.exportedAt, '2026-08-08T12:00:00+00:00');
        // The raw payload must be preserved unmodified for "copy as JSON".
        expect(export.rawJson['user'], isA<Map<String, dynamic>>());
      },
    );

    test(
      'requestAccountDeletion posts confirm=true and an optional reason',
      () async {
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            expect(path, '/account/data-deletion-requests');
            expect(data, <String, dynamic>{
              'confirm': true,
              'reason': 'No longer needed',
            });
            return _envelope(path, <String, dynamic>{
              'success': true,
              'message': 'Data deletion request recorded.',
              'data': <String, dynamic>{
                'id': '42',
                'status': 'pending',
                'requested_at': '2026-08-08T12:00:00+00:00',
              },
            }, statusCode: 202);
          },
        );

        final controller = _controllerWith(client);
        final result = await controller.requestAccountDeletion(
          reason: 'No longer needed',
        );

        expect(result.id, '42');
        expect(result.status, 'pending');
      },
    );

    test(
      'requestAccountDeletion omits reason entirely when not provided',
      () async {
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            expect(data, <String, dynamic>{'confirm': true});
            return _envelope(path, <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'id': '43',
                'status': 'pending',
                'requested_at': '2026-08-08T12:00:00+00:00',
              },
            });
          },
        );

        final controller = _controllerWith(client);
        await controller.requestAccountDeletion();
      },
    );
  });
}
