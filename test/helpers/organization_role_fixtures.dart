import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';

/// Test-only mirror of `App\Enums\OrganizationRole::permissions()` on the
/// backend, for building `OrganizationEntity` fixtures.
///
/// Sprint E (role/permission remediation) deleted the production
/// `OrganizationRolePermissions` class — the app no longer derives
/// permissions from a role name, it consumes whatever
/// `OrganizationMembershipDtoV1.permissions` the backend actually sent. But
/// tests still need a convenient way to say "simulate what the backend
/// would send for an owner/manager/editor/viewer" without spelling out the
/// full permission set at every call site. This lives under test/ only —
/// never imported by lib/ — specifically so it can't silently become a
/// second production source of truth again.
Set<String> permissionsForRole(String role) {
  switch (role.trim().toLowerCase()) {
    case 'owner':
      return OrganizationPermissions.all;
    case 'admin':
      return OrganizationPermissions.all.difference(<String>{
        OrganizationPermissions.organizationTransferOwnership,
        OrganizationPermissions.organizationDelete,
      });
    case 'manager':
      return const <String>{
        OrganizationPermissions.postsViewAll,
        OrganizationPermissions.postsCreate,
        OrganizationPermissions.postsUpdateOwn,
        OrganizationPermissions.postsUpdateAll,
        OrganizationPermissions.postsApprove,
        OrganizationPermissions.postsPublish,
        OrganizationPermissions.postsDeleteOwn,
        OrganizationPermissions.socialAccountsView,
        OrganizationPermissions.socialAccountsCreate,
        OrganizationPermissions.socialAccountsUpdate,
        OrganizationPermissions.socialAccountsConnect,
        OrganizationPermissions.socialAccountsDisconnect,
        OrganizationPermissions.socialAccountsDelete,
        OrganizationPermissions.socialAccountsTest,
        OrganizationPermissions.socialAccountsRefresh,
        OrganizationPermissions.socialAccountsSync,
        OrganizationPermissions.socialPagesView,
        OrganizationPermissions.socialPagesSelect,
        OrganizationPermissions.socialPagesSync,
        OrganizationPermissions.membersView,
        OrganizationPermissions.analyticsView,
        OrganizationPermissions.organizationView,
      };
    case 'editor':
      return const <String>{
        OrganizationPermissions.postsViewOwn,
        OrganizationPermissions.postsCreate,
        OrganizationPermissions.postsUpdateOwn,
        OrganizationPermissions.postsRequestApproval,
        OrganizationPermissions.postsDeleteOwn,
        OrganizationPermissions.socialAccountsView,
        OrganizationPermissions.socialPagesView,
        OrganizationPermissions.membersView,
        OrganizationPermissions.analyticsView,
        OrganizationPermissions.organizationView,
      };
    case 'viewer':
      return const <String>{
        OrganizationPermissions.postsViewAll,
        OrganizationPermissions.socialAccountsView,
        OrganizationPermissions.socialPagesView,
        OrganizationPermissions.membersView,
        OrganizationPermissions.analyticsView,
        OrganizationPermissions.organizationView,
      };
    default:
      return const <String>{};
  }
}
