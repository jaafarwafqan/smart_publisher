import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/storage_provider.dart';

part 'guard_state_provider.g.dart';

enum UserRole { guest, publisher, admin }

final class GuardStorageKeys {
  GuardStorageKeys._();

  static const authToken = 'auth.token';
  static const userRole = 'auth.user.role';
  static const firstLaunchCompleted = 'app.first_launch_completed';
}

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
