import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecretsManager {
  Future<void> setSecret(String key, String value);

  Future<String?> getSecret(String key);

  Future<void> removeSecret(String key);
}

class InMemorySecretsManager implements SecretsManager {
  InMemorySecretsManager() : _store = <String, String>{};

  final Map<String, String> _store;

  @override
  Future<void> setSecret(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> getSecret(String key) async {
    return _store[key];
  }

  @override
  Future<void> removeSecret(String key) async {
    _store.remove(key);
  }
}

class PlatformSecureSecretsManager implements SecretsManager {
  const PlatformSecureSecretsManager({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> setSecret(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> getSecret(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> removeSecret(String key) {
    return _storage.delete(key: key);
  }
}
