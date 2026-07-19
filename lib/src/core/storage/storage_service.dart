abstract interface class StorageService {
  Future<void> writeString(String key, String value);
  Future<String?> readString(String key);
  Future<void> delete(String key);
  Future<void> clear();
}
