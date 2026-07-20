import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'secure_storage_service.dart';
import 'storage_service.dart';

part 'storage_provider.g.dart';

@Riverpod(keepAlive: true)
StorageService storageService(StorageServiceRef ref) {
  return SecureStorageService();
}
