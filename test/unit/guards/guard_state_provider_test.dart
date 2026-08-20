import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/events/event_bus.dart';
import 'package:smart_publisher/src/core/events/event_dispatcher.dart'
    as app_events;
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';
import 'package:smart_publisher/src/features/auth/application/auth_event_publisher.dart';
import 'package:smart_publisher/src/features/auth/application/auth_session_controller.dart';

import '../../helpers/fake_network_client.dart';

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

void main() {
  group('Guard State Providers', () {
    test('authState true when token exists', () async {
      final storage = InMemoryStorageService();
      await storage.writeString(GuardStorageKeys.authToken, 'token');

      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final value = await container.read(authStateProvider.future);
      expect(value, isTrue);
    });

    test('firstLaunch false when completed flag is true', () async {
      final storage = InMemoryStorageService();
      await storage.writeString(GuardStorageKeys.firstLaunchCompleted, 'true');

      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final value = await container.read(firstLaunchProvider.future);
      expect(value, isFalse);
    });

    test('currentUserRole parses publisher role', () async {
      final storage = InMemoryStorageService();
      await storage.writeString(GuardStorageKeys.userRole, 'publisher');

      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final role = await container.read(currentUserRoleProvider.future);
      expect(role, UserRole.publisher);
    });

    // Sprint E (role/permission remediation): currentPlatformAdminProvider
    // no longer trusts local storage alone — it re-verifies live via
    // GET /me on every read/refresh (see the provider's own docblock).
    test(
      'currentPlatformAdmin reads the live is_super_admin flag from GET /me',
      () async {
        final client = FakeNetworkClient(
          getHandler: (path) async {
            expect(path, '/me');
            return _meEnvelope(isSuperAdmin: true);
          },
        );

        final container = ProviderContainer(
          overrides: <Override>[
            authSessionControllerProvider.overrideWithValue(
              _controllerWith(client),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(
          await container.read(currentPlatformAdminProvider.future),
          isTrue,
        );
      },
    );

    test(
      'currentPlatformAdmin fails closed to false when the backend says no',
      () async {
        final client = FakeNetworkClient(
          getHandler: (path) async => _meEnvelope(isSuperAdmin: false),
        );

        final container = ProviderContainer(
          overrides: <Override>[
            authSessionControllerProvider.overrideWithValue(
              _controllerWith(client),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(
          await container.read(currentPlatformAdminProvider.future),
          isFalse,
        );
      },
    );

    test(
      'currentPlatformAdmin fails closed to false when the network call errors, '
      'never trusting a stale local value',
      () async {
        final client = FakeNetworkClient(
          getHandler: (path) async => throw StateError('network unavailable'),
        );

        final container = ProviderContainer(
          overrides: <Override>[
            authSessionControllerProvider.overrideWithValue(
              _controllerWith(client),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(
          await container.read(currentPlatformAdminProvider.future),
          isFalse,
        );
      },
    );
  });
}

Response<dynamic> _meEnvelope({required bool isSuperAdmin}) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: '/me'),
    statusCode: 200,
    data: <String, dynamic>{
      'success': true,
      'message': 'OK',
      'data': <String, dynamic>{
        'user': <String, dynamic>{
          'two_factor_enabled': false,
          'email_verified': true,
          'is_super_admin': isSuperAdmin,
        },
      },
    },
  );
}
