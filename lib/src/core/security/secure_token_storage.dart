import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'secrets_manager.dart';
import 'token_bundle.dart';

abstract interface class SecureTokenStorage {
  Future<void> saveTokens(TokenBundle bundle);

  Future<TokenBundle?> readTokens();

  Future<void> clearTokens();
}

// Was wrapping the JSON payload in DefaultEncryptionService (XOR + base64)
// before handing it to secretsManager, with the "encryption key" stored via
// the very same secretsManager next to the ciphertext it was meant to
// protect — a lock with the key taped to the door, and a well-known
// plaintext prefix ({"access_token":") on top of that. Removed: the inner
// layer added no real confidentiality, only the appearance of it.
//
// secretsManager (PlatformSecureSecretsManager) is flutter_secure_storage,
// which is already the real protection here — Keychain on iOS, Keystore on
// Android, hardware-backed where the device supports it. Storing JSON
// directly in it is not "unencrypted"; it's one fewer, worthless layer.
//
// On web, flutter_secure_storage falls back to the browser's own storage
// (see storage_provider.dart), which any page XSS can read. refresh_token is
// therefore never persisted on web — only access_token is — so a successful
// XSS caps out at stealing a short-lived access token instead of the full
// 30-day refresh window. access_token itself must still be persisted (not
// memory-only) on web: the Facebook OAuth consent redirect reinitializes the
// whole Flutter app on return, and an in-memory-only token would be lost at
// exactly that point (see storage_provider.dart for the incident this fixed).
class EncryptedTokenStorage implements SecureTokenStorage {
  EncryptedTokenStorage({
    required this.secretsManager,
    this.storageKey = 'auth.tokens',
  });

  final SecretsManager secretsManager;
  final String storageKey;

  @override
  Future<void> saveTokens(TokenBundle bundle) async {
    final payload = jsonEncode(<String, dynamic>{
      'access_token': bundle.accessToken,
      'refresh_token': kIsWeb ? '' : bundle.refreshToken,
      'expires_at': bundle.expiresAt.toIso8601String(),
      'token_type': bundle.tokenType,
      'scopes': bundle.scopes.toList(),
    });
    await secretsManager.setSecret(storageKey, payload);
  }

  @override
  Future<TokenBundle?> readTokens() async {
    final raw = await secretsManager.getSecret(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;

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
}
