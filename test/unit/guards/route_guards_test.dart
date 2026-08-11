import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/router/route_guards.dart';
import 'package:smart_publisher/src/core/router/route_names.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';

import '../../helpers/organization_role_fixtures.dart';

final _guardRedirectProvider = FutureProvider.family<String?, String>(
  (ref, path) => RouteGuards.guardPath(path, ref),
);

OrganizationAccessState _accessFor(String role) {
  final membership = OrganizationEntity(
    id: 1,
    name: 'Release Team',
    slug: 'release-team',
    role: role,
    isCurrent: true,
    permissions: permissionsForRole(role),
  );
  return OrganizationAccessState.active(
    memberships: <OrganizationEntity>[membership],
    currentOrganization: membership,
  );
}

ProviderContainer _containerFor(
  OrganizationAccessState access, {
  bool authenticated = true,
  String? persistedAccountRole,
  bool platformAdmin = false,
}) {
  final storage = InMemoryStorageService();
  return ProviderContainer(
    overrides: <Override>[
      storageServiceProvider.overrideWithValue(storage),
      authStateProvider.overrideWith((_) async => authenticated),
      currentOrganizationAccessProvider.overrideWith((_) async => access),
      currentPlatformAdminProvider.overrideWith((_) async => platformAdmin),
      if (persistedAccountRole != null)
        currentUserRoleProvider.overrideWith(
          (_) async => UserRoleStorage.fromStorageValue(persistedAccountRole),
        ),
    ],
  );
}

Future<String?> _redirect(ProviderContainer container, String path) {
  // Real navigation always re-evaluates the guard fresh (GoRouter calls
  // RouteGuards.guard() anew on every navigation event) — invalidate the
  // family provider's cache first so a test can legitimately call the same
  // path twice on one container and observe session state (like
  // hasLandedSuperAdminSessionProvider) changing between the two calls.
  container.invalidate(_guardRedirectProvider(path));
  return container.read(_guardRedirectProvider(path).future);
}

void main() {
  group('RouteGuards organization permissions', () {
    test(
      'all backend membership roles receive only their permitted post routes',
      () async {
        const expectedCreateRedirects = <String, String?>{
          'owner': null,
          'admin': null,
          'manager': null,
          'editor': null,
          'viewer': RouteNames.dashboardPath,
        };

        for (final entry in expectedCreateRedirects.entries) {
          final container = _containerFor(_accessFor(entry.key));
          addTearDown(container.dispose);

          expect(await _redirect(container, RouteNames.postsListPath), isNull);
          expect(
            await _redirect(container, RouteNames.postsCreatePath),
            entry.value,
            reason: '${entry.key} post-create route',
          );
        }
      },
    );

    test(
      'only membership settings permission can enter administration',
      () async {
        for (final role in <String>['owner', 'admin']) {
          final container = _containerFor(_accessFor(role));
          addTearDown(container.dispose);
          expect(
            await _redirect(container, RouteNames.administrationPath),
            isNull,
          );
        }

        for (final role in <String>['manager', 'editor', 'viewer']) {
          final container = _containerFor(_accessFor(role));
          addTearDown(container.dispose);
          expect(
            await _redirect(container, RouteNames.administrationPath),
            RouteNames.dashboardPath,
            reason: '$role cannot manage organization settings',
          );
        }
      },
    );

    test(
      'a persisted generic admin role cannot override a viewer membership',
      () async {
        final container = _containerFor(
          _accessFor('viewer'),
          persistedAccountRole: 'admin',
        );
        addTearDown(container.dispose);

        expect(
          await _redirect(container, RouteNames.administrationPath),
          RouteNames.dashboardPath,
        );
        expect(
          await _redirect(container, RouteNames.postsCreatePath),
          RouteNames.dashboardPath,
        );
      },
    );

    test(
      'platform administration is independent from organization access',
      () async {
        final noOrganization = OrganizationAccessState.noActiveOrganization(
          memberships: const <OrganizationEntity>[],
        );
        final superAdmin = _containerFor(noOrganization, platformAdmin: true);
        final regularUser = _containerFor(
          _accessFor('owner'),
          platformAdmin: false,
        );
        addTearDown(superAdmin.dispose);
        addTearDown(regularUser.dispose);

        expect(
          await _redirect(superAdmin, RouteNames.platformAdministrationPath),
          isNull,
        );
        expect(
          await _redirect(superAdmin, RouteNames.platformUsersPath),
          isNull,
        );
        expect(
          await _redirect(superAdmin, RouteNames.dashboardPath),
          RouteNames.platformAdministrationPath,
        );
        expect(
          await _redirect(regularUser, RouteNames.platformUsersPath),
          RouteNames.dashboardPath,
        );

        // The gap this guards against: a pure platform-admin account has
        // zero organization memberships (noOrganization above), so any
        // route other than /dashboard and /platform/* must still land back
        // in the platform workspace instead of falling through to the
        // organization-access checks below and dead-ending in the
        // organization switcher.
        for (final path in <String>[
          RouteNames.settingsPath,
          RouteNames.postsListPath,
          RouteNames.calendarPath,
          RouteNames.organizationsPath,
        ]) {
          expect(
            await _redirect(superAdmin, path),
            RouteNames.platformAdministrationPath,
            reason: path,
          );
        }
      },
    );

    test(
      'a super_admin session lands on the platform overview on its first '
      'navigation even when the current URL is a deep /platform/* sub-route',
      () async {
        // Regression coverage for the bug reported 2026-08-10: on a hard
        // page reload (or a stale deep link/bookmark), Flutter Web's
        // GoRouter evaluates the browser's actual current URL directly —
        // never the splash-only redirect at path=='/' — so a super_admin
        // whose browser happened to be showing /platform/users landed
        // straight back on the Users screen instead of the system overview.
        final noOrganization = OrganizationAccessState.noActiveOrganization(
          memberships: const <OrganizationEntity>[],
        );

        final freshUsers = _containerFor(noOrganization, platformAdmin: true);
        addTearDown(freshUsers.dispose);
        expect(
          await _redirect(freshUsers, RouteNames.platformUsersPath),
          RouteNames.platformAdministrationPath,
        );

        final freshOrganizations = _containerFor(
          noOrganization,
          platformAdmin: true,
        );
        addTearDown(freshOrganizations.dispose);
        expect(
          await _redirect(
            freshOrganizations,
            RouteNames.platformOrganizationsPath,
          ),
          RouteNames.platformAdministrationPath,
        );

        // But once landed, further in-app navigation to the very same
        // sub-route (e.g. clicking the "إدارة المستخدمين" header button)
        // must go through untouched.
        expect(
          await _redirect(freshUsers, RouteNames.platformUsersPath),
          isNull,
        );

        // And a fresh session that boots directly at the bare overview
        // path never gets an extra redirect either.
        final freshOverview = _containerFor(
          noOrganization,
          platformAdmin: true,
        );
        addTearDown(freshOverview.dispose);
        expect(
          await _redirect(freshOverview, RouteNames.platformAdministrationPath),
          isNull,
        );
      },
    );

    test(
      'closed beta never routes an organization owner to system OAuth secrets',
      () async {
        final container = _containerFor(_accessFor('owner'));
        addTearDown(container.dispose);

        expect(
          await _redirect(container, RouteNames.oauthProviderSettingsPath),
          RouteNames.administrationPath,
        );
      },
    );

    test(
      'a super_admin session can actually reach OAuth provider settings',
      () async {
        // Sprint D (role/permission remediation): oauthProviderSettingsPath
        // lives outside the /platform prefix, so without the explicit
        // allowance in _isPlatformAdministrationRoute() a super_admin
        // session would be bounced straight back to /platform by the
        // isPlatformAdmin branch — the same regression the "platform
        // administration is independent" test above guards against for
        // every OTHER non-platform route.
        final noOrganization = OrganizationAccessState.noActiveOrganization(
          memberships: const <OrganizationEntity>[],
        );
        final superAdmin = _containerFor(noOrganization, platformAdmin: true);
        addTearDown(superAdmin.dispose);

        expect(
          await _redirect(superAdmin, RouteNames.oauthProviderSettingsPath),
          isNull,
        );
      },
    );

    test(
      'no active organization redirects protected routes to the switcher',
      () async {
        final access = OrganizationAccessState.noActiveOrganization(
          memberships: const <OrganizationEntity>[],
        );
        final container = _containerFor(access);
        addTearDown(container.dispose);

        expect(
          await _redirect(container, RouteNames.postsListPath),
          RouteNames.organizationsPath,
        );
        expect(
          await _redirect(container, RouteNames.organizationsPath),
          isNull,
        );
      },
    );

    test(
      'membership loading errors land on the switcher instead of dashboard data',
      () async {
        final storage = InMemoryStorageService();
        final container = ProviderContainer(
          overrides: <Override>[
            storageServiceProvider.overrideWithValue(storage),
            authStateProvider.overrideWith((_) async => true),
            currentOrganizationAccessProvider.overrideWith(
              (_) async => throw const OrganizationAccessException(
                'Membership service unavailable.',
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(
          await _redirect(container, RouteNames.analyticsPath),
          RouteNames.organizationsPath,
        );
      },
    );

    test(
      'unauthenticated users are sent to login before organization checks',
      () async {
        final container = _containerFor(
          _accessFor('owner'),
          authenticated: false,
        );
        addTearDown(container.dispose);

        expect(
          await _redirect(container, RouteNames.postsCreatePath),
          RouteNames.loginPath,
        );
      },
    );

    test(
      'Sprint 4 pre-auth routes stay reachable while unauthenticated',
      () async {
        final container = _containerFor(
          _accessFor('owner'),
          authenticated: false,
        );
        addTearDown(container.dispose);

        for (final path in <String>[
          RouteNames.registerPath,
          RouteNames.forgotPasswordPath,
          RouteNames.resetPasswordPath,
          RouteNames.twoFactorChallengePath,
        ]) {
          expect(await _redirect(container, path), isNull, reason: path);
        }
      },
    );

    test(
      'Sprint 4 pre-auth routes bounce an already-authenticated user to the dashboard',
      () async {
        final container = _containerFor(_accessFor('owner'));
        addTearDown(container.dispose);

        for (final path in <String>[
          RouteNames.registerPath,
          RouteNames.forgotPasswordPath,
          RouteNames.resetPasswordPath,
          RouteNames.twoFactorChallengePath,
        ]) {
          expect(
            await _redirect(container, path),
            RouteNames.dashboardPath,
            reason: path,
          );
        }
      },
    );

    test(
      'two-factor setup is reachable by every role, unlike the rest of /settings',
      () async {
        for (final role in <String>[
          'owner',
          'admin',
          'manager',
          'editor',
          'viewer',
        ]) {
          final container = _containerFor(_accessFor(role));
          addTearDown(container.dispose);

          expect(
            await _redirect(container, RouteNames.twoFactorSetupPath),
            isNull,
            reason: role,
          );
        }
      },
    );

    test(
      'organization members requires members.view but not settings.manage',
      () async {
        for (final role in <String>[
          'owner',
          'admin',
          'manager',
          'editor',
          'viewer',
        ]) {
          final container = _containerFor(_accessFor(role));
          addTearDown(container.dispose);

          // Every documented role template grants members.view.
          expect(
            await _redirect(container, RouteNames.organizationMembersPath),
            isNull,
            reason: role,
          );
        }
      },
    );

    test(
      'account data export/deletion are reachable by every role, unlike the rest of /settings',
      () async {
        for (final role in <String>[
          'owner',
          'admin',
          'manager',
          'editor',
          'viewer',
        ]) {
          final container = _containerFor(_accessFor(role));
          addTearDown(container.dispose);

          expect(
            await _redirect(container, RouteNames.accountDataExportPath),
            isNull,
            reason: '$role (export)',
          );
          expect(
            await _redirect(container, RouteNames.accountDataDeletionPath),
            isNull,
            reason: '$role (deletion)',
          );
        }
      },
    );
  });

  group('RouteGuards help center', () {
    test(
      '/about renders identically unauthenticated, authenticated, and for a platform admin',
      () async {
        final unauthenticated = _containerFor(
          OrganizationAccessState.noActiveOrganization(
            memberships: const <OrganizationEntity>[],
          ),
          authenticated: false,
        );
        final orgMember = _containerFor(_accessFor('viewer'));
        final noOrganization = OrganizationAccessState.noActiveOrganization(
          memberships: const <OrganizationEntity>[],
        );
        final superAdmin = _containerFor(noOrganization, platformAdmin: true);
        addTearDown(unauthenticated.dispose);
        addTearDown(orgMember.dispose);
        addTearDown(superAdmin.dispose);

        // Unauthenticated visitors never even reach a login redirect for it.
        expect(await _redirect(unauthenticated, RouteNames.aboutPath), isNull);
        expect(await _redirect(orgMember, RouteNames.aboutPath), isNull);
        // A super_admin session is bounced from almost every non-/platform
        // route (see the "platform administration is independent" test
        // above) — /about is the deliberate exception.
        expect(await _redirect(superAdmin, RouteNames.aboutPath), isNull);
      },
    );

    test(
      '/help and /help/guide are reachable without an active organization',
      () async {
        final access = OrganizationAccessState.noActiveOrganization(
          memberships: const <OrganizationEntity>[],
        );
        final container = _containerFor(access);
        addTearDown(container.dispose);

        expect(await _redirect(container, RouteNames.helpCenterPath), isNull);
        expect(await _redirect(container, RouteNames.userGuidePath), isNull);
      },
    );

    test(
      '/help and /help/guide are reachable by every organization role',
      () async {
        for (final role in <String>[
          'owner',
          'admin',
          'manager',
          'editor',
          'viewer',
        ]) {
          final container = _containerFor(_accessFor(role));
          addTearDown(container.dispose);

          expect(
            await _redirect(container, RouteNames.helpCenterPath),
            isNull,
            reason: role,
          );
          expect(
            await _redirect(container, RouteNames.userGuidePath),
            isNull,
            reason: role,
          );
        }
      },
    );

    test(
      'a platform admin session is bounced away from the organization-scoped guide',
      () async {
        final noOrganization = OrganizationAccessState.noActiveOrganization(
          memberships: const <OrganizationEntity>[],
        );
        final superAdmin = _containerFor(noOrganization, platformAdmin: true);
        addTearDown(superAdmin.dispose);

        expect(
          await _redirect(superAdmin, RouteNames.helpCenterPath),
          RouteNames.platformAdministrationPath,
        );
        expect(
          await _redirect(superAdmin, RouteNames.userGuidePath),
          RouteNames.platformAdministrationPath,
        );
      },
    );

    test(
      'an unauthenticated visitor is sent to login for /help but not /about',
      () async {
        final unauthenticated = _containerFor(
          OrganizationAccessState.noActiveOrganization(
            memberships: const <OrganizationEntity>[],
          ),
          authenticated: false,
        );
        addTearDown(unauthenticated.dispose);

        expect(
          await _redirect(unauthenticated, RouteNames.helpCenterPath),
          RouteNames.loginPath,
        );
        expect(await _redirect(unauthenticated, RouteNames.aboutPath), isNull);
      },
    );
  });
}
