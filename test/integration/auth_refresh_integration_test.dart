import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/security/encryption_service.dart';
import 'package:smart_publisher/src/core/security/secrets_manager.dart';
import 'package:smart_publisher/src/core/security/secure_token_storage.dart';
import 'package:smart_publisher/src/core/security/token_bundle.dart';
import 'package:smart_publisher/src/core/security/token_lifecycle_manager.dart';

void main() {
  group('Integration - Token Refresh', () {
    test('refreshes expired access token and persists rotated bundle', () async {
      final tokenStorage = EncryptedTokenStorage(
        secretsManager: InMemorySecretsManager(),
        encryptionService: const DefaultEncryptionService(),
      );

      await tokenStorage.saveTokens(
        TokenBundle(
          accessToken: 'expired-access',
          refreshToken: 'refresh-1',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
          scopes: const <String>{'posts.read'},
        ),
      );

      final manager = TokenLifecycleManager(
        tokenStorage: tokenStorage,
        refreshExecutor: (refreshToken) async {
          expect(refreshToken, 'refresh-1');
          return TokenBundle(
            accessToken: 'new-access',
            refreshToken: 'refresh-2',
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
            scopes: const <String>{'posts.read', 'posts.write'},
          );
        },
      );

      final accessToken = await manager.getValidAccessToken();
      expect(accessToken, 'new-access');

      final stored = await tokenStorage.readTokens();
      expect(stored, isNotNull);
      expect(stored!.accessToken, 'new-access');
      expect(stored.refreshToken, 'refresh-2');
      expect(stored.scopes.contains('posts.write'), isTrue);
    });

    test('returns null when refresh token is missing', () async {
      final tokenStorage = EncryptedTokenStorage(
        secretsManager: InMemorySecretsManager(),
        encryptionService: const DefaultEncryptionService(),
      );

      await tokenStorage.saveTokens(
        TokenBundle(
          accessToken: 'expired-access',
          refreshToken: '',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );

      final manager = TokenLifecycleManager(
        tokenStorage: tokenStorage,
        refreshExecutor: (_) async {
          fail('refreshExecutor must not be called when refresh token is empty');
        },
      );

      final accessToken = await manager.getValidAccessToken();
      expect(accessToken, isNull);
    });
  });
}
