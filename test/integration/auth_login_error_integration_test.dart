import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/security/encryption_service.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';

import '../helpers/fake_network_client.dart';

void main() {
  test('AuthSessionController surfaces backend login message', () async {
    final client = FakeNetworkClient(
      postHandler: (path, data) async {
        throw DioException(
          requestOptions: RequestOptions(path: path),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 401,
            data: <String, dynamic>{'message': 'Invalid credentials provided.'},
          ),
          type: DioExceptionType.badResponse,
        );
      },
    );
    final controller = AuthSessionController(
      networkClient: client,
      tokenLifecycleManager: TokenLifecycleManager(
        tokenStorage: EncryptedTokenStorage(
          secretsManager: InMemorySecretsManager(),
          encryptionService: const DefaultEncryptionService(),
        ),
      ),
      storageService: InMemoryStorageService(),
      authEventPublisher: AuthEventPublisher(
        app_events.EventDispatcher(EventBus()),
      ),
    );

    await expectLater(
      () => controller.login(email: 'bad@example.com', password: 'wrongpass'),
      throwsA(
        isA<AuthSessionException>().having(
          (error) => error.message,
          'message',
          'Invalid credentials provided.',
        ),
      ),
    );
  });
}
