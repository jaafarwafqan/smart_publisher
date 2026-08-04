import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/organizations/application/current_organization_access.dart';
import 'guard_state_provider.dart';
import 'route_names.dart';

/// Resolves navigation from authentication plus the selected organization's
/// membership permissions. Laravel remains the enforcement boundary; this is
/// the client-side UX guard and must not use a persisted account-wide role.
final class RouteGuards {
  RouteGuards._();

  static Future<String?> guard(GoRouterState state, Ref ref) {
    return guardPath(state.uri.path, ref);
  }

  /// Path-only entry point so the permission decisions can be tested without
  /// constructing an internal [GoRouterState].
  static Future<String?> guardPath(String path, Ref ref) async {
    final isAuthenticated = await ref.read(authStateProvider.future);

    if (path == RouteNames.splashPath) {
      return isAuthenticated ? RouteNames.dashboardPath : RouteNames.loginPath;
    }

    if (_isAuthenticationRoute(path)) {
      return isAuthenticated ? RouteNames.dashboardPath : null;
    }

    if (!isAuthenticated) {
      return RouteNames.loginPath;
    }

    // Keep this route reachable for users whose active membership expired,
    // who have no selected organization, or whose membership fetch failed.
    // The switcher renders a distinct loading, error, and empty state.
    if (path == RouteNames.organizationsPath) {
      return null;
    }

    OrganizationAccessState access;
    try {
      // Refresh for every guarded navigation. This prevents a membership
      // revoked in another session from remaining trusted in a long-lived
      // Flutter ProviderScope.
      access = await ref.refresh(currentOrganizationAccessProvider.future);
    } on OrganizationAccessException {
      return RouteNames.organizationsPath;
    } catch (_) {
      return RouteNames.organizationsPath;
    }

    if (!access.hasActiveOrganization) {
      return RouteNames.organizationsPath;
    }

    // OAuth client credentials are system-level secrets guarded by Laravel's
    // separate global system-settings capability. Organization membership
    // never grants that capability, so the closed-beta client must not route
    // an organization owner/admin into a guaranteed 403 screen.
    if (path.startsWith(RouteNames.oauthProviderSettingsPath)) {
      return RouteNames.administrationPath;
    }

    final requiredPermissions = _requiredPermissionsFor(path);
    if (requiredPermissions.isEmpty ||
        access.hasAnyPermission(requiredPermissions)) {
      return null;
    }

    return RouteNames.dashboardPath;
  }

  static Set<String> _requiredPermissionsFor(String path) {
    if (path.startsWith(RouteNames.postsCreatePath) ||
        path.startsWith(RouteNames.publisherPath)) {
      return const <String>{OrganizationPermissions.postsCreate};
    }
    if (path.startsWith(RouteNames.postsListPath)) {
      return const <String>{
        OrganizationPermissions.postsViewOwn,
        OrganizationPermissions.postsViewAll,
      };
    }
    if (path.startsWith(RouteNames.mediaLibraryPath)) {
      // The current organization permission enum has no separate media
      // capability. This is the least-privileged target-related grant.
      return const <String>{OrganizationPermissions.socialAccountsView};
    }
    if (path.startsWith(RouteNames.calendarPath)) {
      return const <String>{
        OrganizationPermissions.postsViewOwn,
        OrganizationPermissions.postsViewAll,
      };
    }
    if (path.startsWith(RouteNames.analyticsPath)) {
      return const <String>{OrganizationPermissions.analyticsView};
    }
    if (path.startsWith(RouteNames.settingsPath) ||
        path.startsWith(RouteNames.adminPath) ||
        path.startsWith(RouteNames.administrationPath) ||
        path.startsWith(RouteNames.productionReleasePath)) {
      return const <String>{OrganizationPermissions.settingsManage};
    }

    // Notifications and the dashboard do not currently have a separate
    // member-level capability in the backend contract. An active membership
    // is still required above, and Laravel remains the final boundary.
    return const <String>{};
  }

  static bool _isAuthenticationRoute(String path) {
    return path == RouteNames.loginPath || path == RouteNames.welcomePath;
  }
}
