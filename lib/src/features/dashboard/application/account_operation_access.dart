import '../../organizations/application/current_organization_access.dart';

/// The dashboard's account-management capabilities for the active
/// organization. This is deliberately derived from the remote-backed
/// [OrganizationAccessState], rather than a cached user role or account
/// ownership field. A missing state represents loading, an API error, or no
/// active organization and therefore denies every mutating control.
///
/// Role/permission remediation (2026-08-09): each field now maps to its own
/// narrow `social_accounts.x`/`social_pages.x` permission (see
/// SocialAccountPolicy on the backend) instead of a single `connect`
/// covering create/update/test/refresh/status-change together.
class AccountOperationAccess {
  const AccountOperationAccess({
    required this.canCreate,
    required this.canUpdate,
    required this.canConnect,
    required this.canDisconnect,
    required this.canDelete,
    required this.canTest,
    required this.canRefresh,
    required this.canSyncPages,
    required this.canSelectPages,
  });

  const AccountOperationAccess.denied()
    : canCreate = false,
      canUpdate = false,
      canConnect = false,
      canDisconnect = false,
      canDelete = false,
      canTest = false,
      canRefresh = false,
      canSyncPages = false,
      canSelectPages = false;

  factory AccountOperationAccess.fromOrganizationAccess(
    OrganizationAccessState? access,
  ) {
    if (access == null || !access.hasActiveOrganization) {
      return const AccountOperationAccess.denied();
    }

    return AccountOperationAccess(
      canCreate: access.hasPermission(
        OrganizationPermissions.socialAccountsCreate,
      ),
      canUpdate: access.hasPermission(
        OrganizationPermissions.socialAccountsUpdate,
      ),
      canConnect: access.hasPermission(
        OrganizationPermissions.socialAccountsConnect,
      ),
      canDisconnect: access.hasPermission(
        OrganizationPermissions.socialAccountsDisconnect,
      ),
      canDelete: access.hasPermission(
        OrganizationPermissions.socialAccountsDelete,
      ),
      canTest: access.hasPermission(OrganizationPermissions.socialAccountsTest),
      canRefresh: access.hasPermission(
        OrganizationPermissions.socialAccountsRefresh,
      ),
      canSyncPages: access.hasPermission(
        OrganizationPermissions.socialPagesSync,
      ),
      canSelectPages: access.hasPermission(
        OrganizationPermissions.socialPagesSelect,
      ),
    );
  }

  final bool canCreate;
  final bool canUpdate;
  final bool canConnect;
  final bool canDisconnect;
  final bool canDelete;
  final bool canTest;
  final bool canRefresh;
  final bool canSyncPages;
  final bool canSelectPages;

  bool get canOperateAccount =>
      canCreate || canConnect || canDisconnect || canDelete;
}
