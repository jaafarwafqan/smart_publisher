import 'dart:convert';

import 'encryption_service.dart';
import 'secrets_manager.dart';
import 'token_bundle.dart';

abstract interface class SecureTokenStorage {
  Future<void> saveTokens(TokenBundle bundle);

  Future<TokenBundle?> readTokens();

  Future<void> clearTokens();
}

class EncryptedTokenStorage implements SecureTokenStorage {
  EncryptedTokenStorage({
    required this.secretsManager,
    required this.encryptionService,
    this.storageKey = 'auth.tokens',
    this.encryptionKeyName = 'auth.encryption.key',
  });

  final SecretsManager secretsManager;
  final EncryptionService encryptionService;
  final String storageKey;
  final String encryptionKeyName;

  @override
  Future<void> saveTokens(TokenBundle bundle) async {
    final encryptionKey = await _resolveEncryptionKey();
    final payload = jsonEncode(<String, dynamic>{
      'access_token': bundle.accessToken,
      'refresh_token': bundle.refreshToken,
      'expires_at': bundle.expiresAt.toIso8601String(),
      'token_type': bundle.tokenType,
      'scopes': bundle.scopes.toList(),
    });
    final cipher = encryptionService.encrypt(payload, encryptionKey);
    await secretsManager.setSecret(storageKey, cipher);
  }

  @override
  Future<TokenBundle?> readTokens() async {
    final cipher = await secretsManager.getSecret(storageKey);
    if (cipher == null || cipher.isEmpty) {
      return null;
    }

    final encryptionKey = await _resolveEncryptionKey();
    final payload = encryptionService.decrypt(cipher, encryptionKey);
    final data = jsonDecode(payload) as Map<String, dynamic>;

    return TokenBundle(
      accessToken: (data['access_token'] ?? '') as String,
      refreshToken: (data['refresh_token'] ?? '') as String,
      expiresAt: DateTime.parse(data['expires_at'] as String),
      tokenType: (data['token_type'] ?? 'Bearer') as String,
      scopes: ((data['scopes'] as List<dynamic>? ?? <dynamic>[])
          .map((scope) => scope.toString())
          .toSet()),
    );
  }

  @override
  Future<void> clearTokens() async {
    await secretsManager.removeSecret(storageKey);
  }

  Future<String> _resolveEncryptionKey() async {
    final existing = await secretsManager.getSecret(encryptionKeyName);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated =
        'spk-${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().millisecondsSinceEpoch}';
    await secretsManager.setSecret(encryptionKeyName, generated);
    return generated;
  }
}
