import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../di/app_providers.dart';
import '../storage/storage_provider.dart';
import 'guard_storage_keys.dart';

export 'guard_storage_keys.dart';

part 'guard_state_provider.g.dart';

enum UserRole { guest, publisher, admin }

extension UserRoleStorage on UserRole {
  String toStorageValue() {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.publisher:
        return 'publisher';
      case UserRole.guest:
        return 'guest';
    }
  }

  static UserRole fromStorageValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'publisher':
        return UserRole.publisher;
      default:
        return UserRole.guest;
    }
  }
}

@Riverpod(keepAlive: true)
Future<bool> authState(AuthStateRef ref) async {
  final storage = ref.read(storageServiceProvider);

  // The read (not just the catch below) is retried once: on web
  // specifically, the very first storage read right after a hard page
  // reload can race flutter_secure_storage's own async web backend init
  // (WebCrypto/IndexedDB) and throw transiently — reproduced live landing
  // back from a real cross-origin OAuth redirect (Facebook consent, then
  // back), where this is exactly the first storage read of the fresh page
  // load. A short retry resolves the race in place, so an actually-valid
  // session isn't punted to /login (discarding a just-completed OAuth
  // consent) over what's typically a few milliseconds of backend warm-up.
  for (var attempt = 0; attempt < 2; attempt++) {
    try {
      final token = await storage.readString(GuardStorageKeys.authToken);
      return token != null && token.trim().isNotEmpty;
    } catch (_) {
      if (attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        continue;
      }
      // Second attempt also failed — was uncaught until 2026-08-11, which
      // propagated through RouteGuards.guard's redirect callback and made
      // GoRouter render its generic errorBuilder ("page not found") instead
      // of the correct outcome for "can't confirm a session right now":
      // fail closed to /login, same as every other fail-closed check in
      // this guard chain (currentPlatformAdminProvider,
      // currentOrganizationAccessProvider's catch-all below).
      return false;
    }
  }
  return false;
}

@Riverpod(keepAlive: true)
Future<bool> firstLaunch(FirstLaunchRef ref) async {
  final storage = ref.read(storageServiceProvider);
  final completed = await storage.readString(
    GuardStorageKeys.firstLaunchCompleted,
  );
  if (completed == null) {
    return true;
  }
  return completed.toLowerCase() != 'true';
}

@Riverpod(keepAlive: true)
Future<UserRole> currentUserRole(CurrentUserRoleRef ref) async {
  final storage = ref.read(storageServiceProvider);
  final storedRole = await storage.readString(GuardStorageKeys.userRole);
  return UserRoleStorage.fromStorageValue(storedRole);
}

/// Sprint E (role/permission remediation, 2026-08-09): previously this only
/// read the `is_super_admin` flag written to local storage at login time —
/// unlike [currentOrganizationAccessProvider], it was never re-verified
/// against the backend, so a super_admin flag revoked in another session (or
/// by another platform administrator) stayed trusted on this device until
/// the next login. Now re-verified live via GET /me on every guarded
/// navigation (route_guards.dart calls `ref.refresh(...)`, exactly like the
/// organization-access provider already does), with the same fail-closed
/// default: any error (including "no session") resolves to `false`, never a
/// stale cached `true`.
final currentPlatformAdminProvider = FutureProvider<bool>((ref) async {
  try {
    final status = await ref
        .read(authSessionControllerProvider)
        .fetchCurrentUserStatus();
    return status.isSuperAdmin;
  } catch (_) {
    return false;
  }
});

/// Sprint (2026-08-10): tracks whether a super_admin session has already
/// been routed to its landing page (/platform) once this app process/tab
/// has been running. Starts `false` for every fresh [ProviderContainer] —
/// i.e. every real app boot or hard page reload on web, since Dart statics
/// and provider state alike reset then — and flips to `true` the first
/// time route_guards.dart consumes it. Deliberately a plain [StateProvider]
/// (not persisted storage): the whole point is that it does NOT survive a
/// reload, so a fresh entry always re-evaluates the landing page even if
/// the browser's current URL is a stale deep link into /platform/*.
final hasLandedSuperAdminSessionProvider = StateProvider<bool>((ref) => false);
