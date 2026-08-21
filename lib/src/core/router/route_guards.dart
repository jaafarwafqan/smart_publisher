import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/organizations/application/current_organization_access.dart';
import '../di/app_providers.dart';
import 'guard_state_provider.dart';
import 'route_guard_snapshot_cache.dart';
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
      // 2026-08-11 decision: a super_admin's default landing is the regular
      // dashboard, same as any other user — platform administration is now
      // a place they navigate to via a menu action, not a forced separate
      // workspace. See the isPlatformAdmin route block below for what stays
      // true regardless: /platform/* and oauthProviderSettingsPath are
      // still super_admin-only.
      return isAuthenticated ? RouteNames.dashboardPath : RouteNames.loginPath;
    }

    if (_isAuthenticationRoute(path)) {
      if (!isAuthenticated) {
        return null;
      }
      return RouteNames.dashboardPath;
    }

    if (!isAuthenticated) {
      return RouteNames.loginPath;
    }

    final snapshotCache = ref.read(routeGuardSnapshotCacheProvider);
    final isPlatformAdmin = await snapshotCache.platformAdmin(
      () => ref.refresh(currentPlatformAdminProvider.future),
    );

    // /platform/* and oauthProviderSettingsPath (Sprint D: platform-level
    // OAuth client credentials, super_admin-gated on the backend — see
    // routes/api.php's /admin group) stay super_admin-only in both
    // directions, but a super_admin is no longer forced to live inside
    // them: everything else below (dashboard, posts, ...) is reachable too,
    // same as any other authenticated account.
    if (_isPlatformAdministrationRoute(path) ||
        path.startsWith(RouteNames.oauthProviderSettingsPath)) {
      if (!isPlatformAdmin) {
        // Two distinct non-admin targets, preserved from before this
        // change: /platform/* bounces to the regular dashboard,
        // oauthProviderSettingsPath bounces to the organization-level
        // /administration screen (an org owner/admin's nearest legitimate
        // page, not a bare dashboard).
        return _isPlatformAdministrationRoute(path)
            ? RouteNames.dashboardPath
            : RouteNames.administrationPath;
      }

      // Sprint (2026-08-10) deep-link fix, preserved: the first guarded
      // navigation this session must not land a super_admin directly on a
      // /platform/* SUB-route (a stale bookmark or Flutter Web restoring
      // the last URL on a hard reload) — force the overview first. Once
      // landed, this flag stays consumed for the rest of the session, so
      // clicking further into /platform/* afterwards is unaffected.
      // oauthProviderSettingsPath has no "overview" concept, so this only
      // applies to _isPlatformAdministrationRoute paths.
      if (_isPlatformAdministrationRoute(path)) {
        final hasLanded = ref.read(hasLandedSuperAdminSessionProvider);
        if (!hasLanded) {
          ref.read(hasLandedSuperAdminSessionProvider.notifier).state = true;
          if (path != RouteNames.platformAdministrationPath) {
            return RouteNames.platformAdministrationPath;
          }
        }
      }

      return null;
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
      access = await snapshotCache.organizationAccess(
        () => ref.refresh(currentOrganizationAccessProvider.future),
      );
    } on SessionExpiredException {
      // authStateProvider only checks whether a token STRING is stored
      // locally — never whether the backend still honors it. A live report
      // reproduced this: an access token expires, the silent refresh
      // attempt also fails (the refresh token is dead too), and this guard
      // used to treat that identically to "no active organization yet",
      // landing an unauthenticated-in-every-way visitor on the
      // organizations screen, which then failed to load for the exact same
      // reason — a generic-looking error where the real fix was just to
      // log in again. Clear the dead local session and send them to login
      // instead. logout() itself best-effort-POSTs to /auth/logout and
      // swallows that call's own failure, so calling it on an already-dead
      // token is safe.
      await ref.read(authSessionControllerProvider).logout();
      return RouteNames.loginPath;
    } on OrganizationAccessException {
      return RouteNames.organizationsPath;
    } catch (_) {
      return RouteNames.organizationsPath;
    }

    if (!access.hasActiveOrganization) {
      return RouteNames.organizationsPath;
    }

    // oauthProviderSettingsPath is handled entirely by the
    // _isPlatformAdministrationRoute(path) || path.startsWith(...) block
    // above (both the super_admin-allowed and non-admin-bounced cases), so
    // nothing reaches this point for that path.

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
