import '../storage/storage_service.dart';

/// Persists which organization is "active" for this device — read by
/// [OrganizationHeaderInterceptor] on every request (sent as
/// X-Organization-Id) and updated whenever the user switches organizations.
/// This is only ever a *hint* the backend independently verifies against the
/// user's real memberships (see ResolveTenantContext middleware) — storing
/// the wrong value here can't grant access to anything, it can only cause a
/// 403 that prompts picking a valid organization again.
class ActiveOrganizationStore {
  const ActiveOrganizationStore({required this.storage});

  final StorageService storage;

  static const _key = 'active_organization_id';

  Future<int?> read() async {
    final raw = await storage.readString(_key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }

  Future<void> write(int organizationId) {
    return storage.writeString(_key, organizationId.toString());
  }

  Future<void> clear() {
    return storage.delete(_key);
  }
}
