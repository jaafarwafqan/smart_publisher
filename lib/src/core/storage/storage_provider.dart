import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'secure_storage_service.dart';
import 'storage_service.dart';

part 'storage_provider.g.dart';

// Was `kIsWeb ? InMemoryStorageService() : SecureStorageService()` until
// 2026-08-11. InMemoryStorageService holds everything in a plain in-process
// Map — nothing survives a full page reload, which is exactly what a real
// browser cross-origin OAuth redirect (Facebook/WhatsApp consent, then back)
// does on web: the whole Flutter app reinitializes from scratch, the map is
// gone, and RouteGuards sees no session and bounces straight to /login —
// discarding a completed, approved OAuth consent along with it. Confirmed
// live: this was the very first time this codebase's web build actually
// went through a real cross-origin redirect (README previously admitted no
// web deployment had ever been claimed). flutter_secure_storage (already a
// dependency for the non-web platforms below) has supported web itself all
// along, backed by the browser's own storage — no separate web package
// needed, just stop special-casing kIsWeb away from it.
@Riverpod(keepAlive: true)
StorageService storageService(StorageServiceRef ref) {
  return SecureStorageService();
}
