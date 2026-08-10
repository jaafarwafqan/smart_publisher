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
  final token = await storage.readString(GuardStorageKeys.authToken);
  return token != null && token.trim().isNotEmpty;
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
