import '../../organizations/application/current_organization_access.dart';

/// The dashboard's account-management capabilities for the active
/// organization. This is deliberately derived from the remote-backed
/// [OrganizationAccessState], rather than a cached user role or account
/// ownership field. A missing state represents loading, an API error, or no
/// active organization and therefore denies every mutating control.
class AccountOperationAccess {
  const AccountOperationAccess({
    required this.canConnect,
    required this.canDisconnect,
    required this.canManagePages,
  });

  const AccountOperationAccess.denied()
    : canConnect = false,
      canDisconnect = false,
      canManagePages = false;

  factory AccountOperationAccess.fromOrganizationAccess(
    OrganizationAccessState? access,
  ) {
    if (access == null || !access.hasActiveOrganization) {
      return const AccountOperationAccess.denied();
    }

    return AccountOperationAccess(
      // Token refresh and connection health checks use the same server-side
      // `social_accounts.connect` policy as connecting/re-authenticating.
      canConnect: access.hasPermission(
        OrganizationPermissions.socialAccountsConnect,
      ),
      canDisconnect: access.hasPermission(
        OrganizationPermissions.socialAccountsDisconnect,
      ),
      canManagePages: access.hasPermission(
        OrganizationPermissions.socialPagesManage,
      ),
    );
  }

  final bool canConnect;
  final bool canDisconnect;
  final bool canManagePages;

  bool get canOperateAccount => canConnect || canDisconnect;
}
