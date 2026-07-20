import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_service.dart';

class SecureStorageService implements StorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> writeString(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> readString(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  @override
  Future<void> clear() {
    return _storage.deleteAll();
  }
}
