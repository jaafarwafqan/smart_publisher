import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../domain/entities/organization_entity.dart';

/// The permission vocabulary exposed by the organization membership model.
///
/// These values deliberately mirror
/// `App\\Enums\\OrganizationPermission` in the Laravel application. The
/// `/organizations` contract currently returns a membership role, rather than
/// a per-member permission array, so [OrganizationRolePermissions] derives
/// this set from Laravel's fixed role template. Keep the two maps in sync if
/// the backend permission enum or role template changes.
abstract final class OrganizationPermissions {
  static const postsViewOwn = 'posts.view_own';
  static const postsViewAll = 'posts.view_all';
  static const postsCreate = 'posts.create';
  static const postsUpdateOwn = 'posts.update_own';
  static const postsUpdateAll = 'posts.update_all';
  static const postsApprove = 'posts.approve';
  static const postsPublish = 'posts.publish';
  static const postsDeleteOwn = 'posts.delete_own';
  static const postsDeleteAll = 'posts.delete_all';

  static const socialAccountsView = 'social_accounts.view';
  static const socialAccountsConnect = 'social_accounts.connect';
  static const socialAccountsDisconnect = 'social_accounts.disconnect';
  static const socialPagesManage = 'social_pages.manage';

  static const membersView = 'members.view';
  static const membersInvite = 'members.invite';
  static const membersChangeRole = 'members.change_role';
  static const membersRemove = 'members.remove';

  static const analyticsView = 'analytics.view';
  static const settingsManage = 'settings.manage';
  static const organizationTransferOwnership =
      'organization.transfer_ownership';
  static const organizationDelete = 'organization.delete';

  static const all = <String>{
    postsViewOwn,
    postsViewAll,
    postsCreate,
    postsUpdateOwn,
    postsUpdateAll,
    postsApprove,
    postsPublish,
    postsDeleteOwn,
    postsDeleteAll,
    socialAccountsView,
    socialAccountsConnect,
    socialAccountsDisconnect,
    socialPagesManage,
    membersView,
    membersInvite,
    membersChangeRole,
    membersRemove,
    analyticsView,
    settingsManage,
    organizationTransferOwnership,
    organizationDelete,
  };
}

/// The fixed organization-role templates enforced by Laravel.
///
/// UI decisions are made through [OrganizationAccessState.hasPermission],
/// never from the role name itself. The role only exists here because it is
/// the permission-bearing field in the current `/organizations` response.
abstract final class OrganizationRolePermissions {
  static const _manager = <String>{
    OrganizationPermissions.postsViewAll,
    OrganizationPermissions.postsCreate,
    OrganizationPermissions.postsUpdateOwn,
    OrganizationPermissions.postsUpdateAll,
    OrganizationPermissions.postsApprove,
    OrganizationPermissions.postsPublish,
    OrganizationPermissions.postsDeleteOwn,
    OrganizationPermissions.socialAccountsView,
    OrganizationPermissions.socialAccountsConnect,
    OrganizationPermissions.socialAccountsDisconnect,
    OrganizationPermissions.socialPagesManage,
    OrganizationPermissions.membersView,
    OrganizationPermissions.analyticsView,
  };

  static const _editor = <String>{
    OrganizationPermissions.postsViewOwn,
    OrganizationPermissions.postsCreate,
    OrganizationPermissions.postsUpdateOwn,
    OrganizationPermissions.postsDeleteOwn,
    OrganizationPermissions.socialAccountsView,
    OrganizationPermissions.membersView,
    OrganizationPermissions.analyticsView,
  };

  static const _viewer = <String>{
    OrganizationPermissions.postsViewAll,
    OrganizationPermissions.socialAccountsView,
    OrganizationPermissions.membersView,
    OrganizationPermissions.analyticsView,
  };

  static Set<String> forRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
        return OrganizationPermissions.all;
      case 'admin':
        return OrganizationPermissions.all.difference(<String>{
          OrganizationPermissions.organizationTransferOwnership,
          OrganizationPermissions.organizationDelete,
        });
      case 'manager':
        return _manager;
      case 'editor':
        return _editor;
      case 'viewer':
        return _viewer;
      default:
        // A role outside the documented backend contract must never inherit
        // viewer access by accident. Keep the client fail-closed until the
        // API and this map are updated together.
        return const <String>{};
    }
  }
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
      permissions: OrganizationRolePermissions.forRole(
        currentOrganization.role,
      ),
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
  /// directly. This mirrors Laravel's `PostPolicy::publish`: `posts.update_own`
  /// grants the request while `posts.publish` is the direct-execution gate.
  bool get canRequestPostApproval {
    return !hasPermission(OrganizationPermissions.postsPublish) &&
        hasPermission(OrganizationPermissions.postsCreate) &&
        hasPermission(OrganizationPermissions.postsUpdateOwn);
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
