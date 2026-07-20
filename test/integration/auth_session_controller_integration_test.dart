import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/security/encryption_service.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';

import '../helpers/fake_network_client.dart';

void main() {
  group('Integration - AuthSessionController', () {
    test('login persists session and logout clears it', () async {
      final client = FakeNetworkClient(
        postHandler: (path, data) async {
          return Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'access_token': 'access-1',
                'refresh_token': 'refresh-1',
                'expires_in': 3600,
                'scope': 'posts.read posts.write',
                'user': <String, dynamic>{
                  'id': 'user-1',
                  'name': 'Jane Doe',
                  'email': 'jane@example.com',
                  'role': 'publisher',
                },
              },
            },
          );
        },
      );
      final storage = InMemoryStorageService();
      final tokenStorage = EncryptedTokenStorage(
        secretsManager: InMemorySecretsManager(),
        encryptionService: const DefaultEncryptionService(),
      );
      final controller = AuthSessionController(
        networkClient: client,
        tokenLifecycleManager: TokenLifecycleManager(
          tokenStorage: tokenStorage,
        ),
        storageService: storage,
        authEventPublisher: AuthEventPublisher(
          app_events.EventDispatcher(EventBus()),
        ),
      );

      final session = await controller.login(
        email: 'jane@example.com',
        password: 'password123',
      );

      expect(session.user.email, 'jane@example.com');
      expect(session.role, UserRole.publisher);
      expect(await storage.readString(GuardStorageKeys.authToken), 'access-1');
      expect(await storage.readString(GuardStorageKeys.userRole), 'publisher');
      expect(await controller.currentSession(), isNotNull);

      await controller.logout();

      expect(await controller.currentSession(), isNull);
      expect(await storage.readString(GuardStorageKeys.authToken), isNull);
      expect(await storage.readString(GuardStorageKeys.userRole), isNull);
    });
  });
}
