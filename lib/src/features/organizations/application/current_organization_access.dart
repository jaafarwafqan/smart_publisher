import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/result/app_failure.dart';
import '../domain/entities/organization_entity.dart';

/// The permission vocabulary exposed by the organization membership model.
///
/// These values deliberately mirror `App\\Enums\\OrganizationPermission` in
/// the Laravel application — kept here as string constants purely so call
/// sites get a typo-checked reference to compare against, not because
/// Flutter derives the grant set itself. The actual grant set for the active
/// organization comes straight from the backend (see
/// `OrganizationMembershipDtoV1.permissions`, sent by GET /organizations and
/// POST /organizations/{id}/switch) — Sprint E (role/permission remediation)
/// removed the role-name-to-permissions map that used to live here
/// (`OrganizationRolePermissions`), since it required hand-syncing with
/// `App\Enums\OrganizationRole::permissions()` on every change.
abstract final class OrganizationPermissions {
  static const postsViewOwn = 'posts.view_own';
  static const postsViewAll = 'posts.view_all';
  static const postsCreate = 'posts.create';
  static const postsUpdateOwn = 'posts.update_own';
  static const postsUpdateAll = 'posts.update_all';
  static const postsRequestApproval = 'posts.request_approval';
  static const postsApprove = 'posts.approve';
  static const postsPublish = 'posts.publish';
  static const postsDeleteOwn = 'posts.delete_own';
  static const postsDeleteAll = 'posts.delete_all';

  // Role/permission remediation (2026-08-09): social_accounts.connect used
  // to gate create/update/test/refresh/disconnect all at once — split to
  // match the granular App\Enums\OrganizationPermission cases on the
  // backend (see SocialAccountPolicy).
  static const socialAccountsView = 'social_accounts.view';
  static const socialAccountsCreate = 'social_accounts.create';
  static const socialAccountsUpdate = 'social_accounts.update';
  static const socialAccountsConnect = 'social_accounts.connect';
  static const socialAccountsDisconnect = 'social_accounts.disconnect';
  static const socialAccountsDelete = 'social_accounts.delete';
  static const socialAccountsTest = 'social_accounts.test';
  static const socialAccountsRefresh = 'social_accounts.refresh';
  static const socialAccountsSync = 'social_accounts.sync';

  static const socialPagesView = 'social_pages.view';
  static const socialPagesSelect = 'social_pages.select';
  static const socialPagesSync = 'social_pages.sync';

  static const membersView = 'members.view';
  static const membersInvite = 'members.invite';
  static const membersChangeRole = 'members.change_role';
  static const membersRemove = 'members.remove';

  static const analyticsView = 'analytics.view';
  static const settingsManage = 'settings.manage';
  static const organizationView = 'organization.view';
  static const organizationUpdate = 'organization.update';
  static const organizationTransferOwnership =
      'organization.transfer_ownership';
  static const organizationDelete = 'organization.delete';
  static const auditLogsView = 'audit_logs.view';

  static const all = <String>{
    postsViewOwn,
    postsViewAll,
    postsCreate,
    postsUpdateOwn,
    postsUpdateAll,
    postsRequestApproval,
    postsApprove,
    postsPublish,
    postsDeleteOwn,
    postsDeleteAll,
    socialAccountsView,
    socialAccountsCreate,
    socialAccountsUpdate,
    socialAccountsConnect,
    socialAccountsDisconnect,
    socialAccountsDelete,
    socialAccountsTest,
    socialAccountsRefresh,
    socialAccountsSync,
    socialPagesView,
    socialPagesSelect,
    socialPagesSync,
    membersView,
    membersInvite,
    membersChangeRole,
    membersRemove,
    analyticsView,
    settingsManage,
    organizationView,
    organizationUpdate,
    organizationTransferOwnership,
    organizationDelete,
    auditLogsView,
  };
}

/// A resolved active membership and the permissions it grants for this
/// organization. A successful organization response with no current
/// membership is represented by [hasActiveOrganization] being false; a
/// transport/API failure is intentionally surfaced as provider error instead
/// of being converted to an empty organization list.
class OrganizationAccessState {
  OrganizationAccessState._({
    required this.memberships,
    required this.currentOrganization,
    required Set<String> permissions,
  }) : _permissions = Set<String>.unmodifiable(permissions);

  factory OrganizationAccessState.active({
    required List<OrganizationEntity> memberships,
    required OrganizationEntity currentOrganization,
  }) {
    return OrganizationAccessState._(
      memberships: List<OrganizationEntity>.unmodifiable(memberships),
      currentOrganization: currentOrganization,
      permissions: currentOrganization.permissions,
    );
  }

  factory OrganizationAccessState.noActiveOrganization({
    required List<OrganizationEntity> memberships,
  }) {
    return OrganizationAccessState._(
      memberships: List<OrganizationEntity>.unmodifiable(memberships),
      currentOrganization: null,
      permissions: const <String>{},
    );
  }

  final List<OrganizationEntity> memberships;
  final OrganizationEntity? currentOrganization;
  final Set<String> _permissions;

  bool get hasActiveOrganization => currentOrganization != null;

  bool get hasMemberships => memberships.isNotEmpty;

  bool hasPermission(String permission) {
    return hasActiveOrganization && _permissions.contains(permission);
  }

  bool hasAnyPermission(Iterable<String> permissions) {
    return permissions.any(hasPermission);
  }

  /// Editors can submit their own post requests, but cannot execute them
  /// directly. This mirrors Laravel's `PostPolicy::publish`:
  /// `posts.request_approval` (or, as a fallback for a role holding
  /// `posts.update_own` without the newer explicit grant) is what allows
  /// submitting the request, while `posts.publish` is the direct-execution
  /// gate.
  bool get canRequestPostApproval {
    return !hasPermission(OrganizationPermissions.postsPublish) &&
        hasPermission(OrganizationPermissions.postsCreate) &&
        (hasPermission(OrganizationPermissions.postsRequestApproval) ||
            hasPermission(OrganizationPermissions.postsUpdateOwn));
  }

  bool get canPublishOrRequestApproval {
    return hasPermission(OrganizationPermissions.postsPublish) ||
        canRequestPostApproval;
  }
}

class OrganizationAccessException implements Exception {
  const OrganizationAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Distinct from [OrganizationAccessException]: this means the session
/// itself is dead (the access token expired AND the refresh attempt also
/// failed — see RefreshTokenInterceptor, which only lets a 401 propagate
/// this far once refresh has already been tried and lost), not "you have no
/// active organization" or "the request failed for some other reason".
/// authStateProvider only checks whether a token string is stored locally,
/// never whether the backend still honors it — so without this distinction,
/// a truly-expired session looked identical to a live one right up until
/// this provider's live GET /organizations call, and callers had no way to
/// tell "show the organizations screen" apart from "send this person back
/// to login." See RouteGuards.guardPath, the reason this exists.
class SessionExpiredException implements Exception {
  const SessionExpiredException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The single client-side source of truth for the selected organization and
/// its membership permissions. It is deliberately remote-backed: persisted
/// account roles and the locally stored organization id are never treated as
/// authorization facts.
final currentOrganizationAccessProvider =
    FutureProvider<OrganizationAccessState>((ref) async {
      final result = await ref
          .watch(organizationRepositoryProvider)
          .getMyOrganizations();

      if (!result.isSuccess) {
        if (result.failure is AuthenticationFailure) {
          throw SessionExpiredException(
            result.message ?? 'Your session has expired.',
          );
        }
        throw OrganizationAccessException(
          result.message ?? 'Unable to load organization access.',
        );
      }

      final memberships = result.data ?? const <OrganizationEntity>[];
      final current = memberships.where((organization) {
        return organization.isCurrent && organization.id > 0;
      }).firstOrNull;

      final store = ref.read(activeOrganizationStoreProvider);
      if (current == null) {
        // The local value is only an HTTP header hint. Clear it once the
        // backend confirms there is no active membership so it cannot keep
        // selecting an expired organization on later requests.
        await store.clear();
        return OrganizationAccessState.noActiveOrganization(
          memberships: memberships,
        );
      }

      // Hydrate the request header after a fresh login/app launch. This is
      // not an authorization decision; Laravel independently validates it.
      await store.write(current.id);
      return OrganizationAccessState.active(
        memberships: memberships,
        currentOrganization: current,
      );
    });

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
