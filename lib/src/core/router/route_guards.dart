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
    // Sprint (Help Center, 2026-08-10): pure product info — must render
    // identically whether the visitor is unauthenticated, a regular
    // organization member, or a platform administrator. Checked before
    // every other branch below (including the platform-admin bounce and
    // the `!isAuthenticated` redirect to login) so none of them ever catch
    // it.
    if (path == RouteNames.aboutPath) {
      return null;
    }

    final isAuthenticated = await ref.read(authStateProvider.future);

    if (path == RouteNames.splashPath) {
      if (!isAuthenticated) {
        return RouteNames.loginPath;
      }
      final isPlatformAdmin = await ref.read(
        currentPlatformAdminProvider.future,
      );
      return isPlatformAdmin
          ? RouteNames.platformAdministrationPath
          : RouteNames.dashboardPath;
    }

    if (_isAuthenticationRoute(path)) {
      if (!isAuthenticated) {
        return null;
      }
      final isPlatformAdmin = await ref.read(
        currentPlatformAdminProvider.future,
      );
      return isPlatformAdmin
          ? RouteNames.platformAdministrationPath
          : RouteNames.dashboardPath;
    }

    if (!isAuthenticated) {
      return RouteNames.loginPath;
    }

    // A platform administrator has an intentionally separate workspace and
    // never falls through to the organization-scoped app below — not just
    // from /dashboard, but from ANY organization-scoped URL (a stale
    // bookmark, deep link, or a route reached before this account was
    // promoted to platform admin). Checking this before the
    // organization-access lookup further down also matters in practice: a
    // pure platform-admin account typically has zero organization
    // memberships, so without this early return every route except
    // /dashboard and /platform/* would fall through to the "no active
    // organization" branch and dead-end the admin in the organization
    // switcher instead of their own workspace.
    final isPlatformAdmin = await ref.refresh(
      currentPlatformAdminProvider.future,
    );
    if (isPlatformAdmin) {
      // Sprint (2026-08-10): the very first guarded navigation this session
      // must always land the super_admin on the platform overview, never on
      // whatever sub-route happens to be current — a stale deep link, a
      // bookmark, or Flutter Web restoring the last browser URL on a hard
      // reload, all of which reach this branch directly without ever
      // passing through the splash-only redirect above (that one only
      // fires when the path is exactly '/'). Once landed, this flag stays
      // consumed for the rest of the session, so clicking further into
      // /platform/* afterwards (e.g. the "إدارة المستخدمين" header button)
      // is completely unaffected.
      final hasLanded = ref.read(hasLandedSuperAdminSessionProvider);
      if (!hasLanded) {
        ref.read(hasLandedSuperAdminSessionProvider.notifier).state = true;
        // Narrowly targets the deep-link bug itself: a /platform/* SUB-route
        // (users, organizations, audit-log, ...). Anything else — the bare
        // overview itself, oauthProviderSettingsPath, /dashboard, or any
        // other URL — already reaches the correct outcome via the existing
        // allowed-check below, so leave those alone here.
        if (path != RouteNames.platformAdministrationPath &&
            _isPlatformAdministrationRoute(path)) {
          return RouteNames.platformAdministrationPath;
        }
      }

      // Sprint D (role/permission remediation): oauthProviderSettingsPath
      // lives outside the /platform prefix for historical reasons, but is
      // now exclusively super_admin-gated on the backend (see
      // routes/api.php's /admin group) — allow it here specifically, not
      // via _isPlatformAdministrationRoute() itself, since that helper is
      // also used below to redirect a NON-admin session away from it with a
      // different, more specific target (/administration, not /dashboard).
      final allowed =
          _isPlatformAdministrationRoute(path) ||
          path.startsWith(RouteNames.oauthProviderSettingsPath);

      return allowed ? null : RouteNames.platformAdministrationPath;
    }

    if (_isPlatformAdministrationRoute(path)) {
      return RouteNames.dashboardPath;
    }

    // Keep this route reachable for users whose active membership expired,
    // who have no selected organization, or whose membership fetch failed.
    // The switcher renders a distinct loading, error, and empty state.
    if (path == RouteNames.organizationsPath) {
      return null;
    }

    // Sprint (Help Center, 2026-08-10): reachable by any authenticated
    // non-platform-admin member — deliberately NOT gated on having an
    // active organization (same reasoning as organizationsPath above), so
    // a brand-new user with no membership yet can still read "البدء
    // باستخدام النظام". The screens themselves filter content by whatever
    // permissions currentOrganizationAccessProvider does resolve.
    if (path == RouteNames.helpCenterPath ||
        path.startsWith(RouteNames.userGuidePath)) {
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

    // OAuth client credentials are platform-level secrets, guarded by
    // super_admin only (Sprint D moved this off the legacy Spatie
    // system-settings permission — see routes/api.php's /admin group). No
    // organization role, however senior, grants that capability, so an
    // organization owner/admin must not be routed into a guaranteed 403
    // screen. A real super_admin session never reaches this branch at all
    // (it returns from the isPlatformAdmin check above).
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
    // Must be checked before postsListPath below — /posts/approvals also
    // starts with /posts and would otherwise inherit the view-only
    // requirement instead of gating on the approval capability.
    if (path.startsWith(RouteNames.postsApprovalsPath)) {
      return const <String>{OrganizationPermissions.postsApprove};
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
    // Sprint 4 (Commercial SaaS): these two live under /settings/* but must
    // NOT inherit the blanket settingsManage gate below — enabling your
    // own 2FA is a personal security action available to every member
    // regardless of role, and viewing the member list only needs
    // members.view (editors/viewers already hold it), not settings
    // management. Both checks must come before the settingsPath prefix
    // match or they'd never be reached.
    if (path.startsWith(RouteNames.twoFactorSetupPath)) {
      return const <String>{};
    }
    if (path.startsWith(RouteNames.organizationMembersPath)) {
      return const <String>{OrganizationPermissions.membersView};
    }
    // Sprint G (role/permission remediation): must also precede the blanket
    // settingsPath prefix match below — audit_logs.view is narrower than
    // settings.manage, and owner/admin already hold it without necessarily
    // holding settings.manage.
    if (path.startsWith(RouteNames.organizationAuditLogPath)) {
      return const <String>{OrganizationPermissions.auditLogsView};
    }
    // Downloading/deleting YOUR OWN account data is a personal-account
    // action too, same reasoning as two-factor setup above — it isn't
    // gated by any organization permission at all on the backend
    // (AccountDataExportController / AccountDataDeletionController both
    // deliberately skip the 'tenant' middleware).
    if (path.startsWith(RouteNames.accountDataExportPath) ||
        path.startsWith(RouteNames.accountDataDeletionPath)) {
      return const <String>{};
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
    // Sprint 4 (Commercial SaaS): registration, forgot/reset-password, and
    // the 2FA login challenge all happen before a real session token
    // exists (authStateProvider is still false at that point) — they must
    // stay reachable pre-auth, same as login/welcome, and still bounce an
    // already-authenticated user straight to the dashboard.
    return path == RouteNames.loginPath ||
        path == RouteNames.welcomePath ||
        path == RouteNames.registerPath ||
        path == RouteNames.forgotPasswordPath ||
        path == RouteNames.resetPasswordPath ||
        path == RouteNames.twoFactorChallengePath;
  }

  static bool _isPlatformAdministrationRoute(String path) {
    return path.startsWith(RouteNames.platformAdministrationPath);
  }
}
