/// Storage key constants for guard-related local persistence. Split out of
/// `guard_state_provider.dart` (Sprint E, role/permission remediation) so
/// `app_providers.dart` can reference the keys without importing the whole
/// provider file — that file now needs `authSessionControllerProvider` from
/// `app_providers.dart` itself, and a two-way import between them would be
/// circular.
final class GuardStorageKeys {
  GuardStorageKeys._();

  static const authToken = 'auth.token';
  static const userRole = 'auth.user.role';
  static const platformAdmin = 'auth.user.is_platform_admin';
  static const firstLaunchCompleted = 'app.first_launch_completed';
}
