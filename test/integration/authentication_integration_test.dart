import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';

void main() {
  group('Integration - Authentication Guards', () {
    test('login/logout state reflected by providers', () async {
      final storage = InMemoryStorageService();
      final container = ProviderContainer(
        overrides: <Override>[
          storageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(authStateProvider.future), isFalse);

      await storage.writeString(GuardStorageKeys.authToken, 'auth-token');
      container.invalidate(authStateProvider);
      expect(await container.read(authStateProvider.future), isTrue);

      await storage.delete(GuardStorageKeys.authToken);
      container.invalidate(authStateProvider);
      expect(await container.read(authStateProvider.future), isFalse);
    });
  });
}
