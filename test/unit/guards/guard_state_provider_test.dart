import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';

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
  });
}
