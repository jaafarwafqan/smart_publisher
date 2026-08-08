import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/router/guard_state_provider.dart';
import 'package:smart_publisher/src/core/router/route_guards.dart';
import 'package:smart_publisher/src/core/router/route_names.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';

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
}) {
  final storage = InMemoryStorageService();
  return ProviderContainer(
    overrides: <Override>[
      storageServiceProvider.overrideWithValue(storage),
      authStateProvider.overrideWith((_) async => authenticated),
      currentOrganizationAccessProvider.overrideWith((_) async => access),
      if (persistedAccountRole != null)
        currentUserRoleProvider.overrideWith(
          (_) async => UserRoleStorage.fromStorageValue(persistedAccountRole),
        ),
    ],
  );
}

Future<String?> _redirect(ProviderContainer container, String path) {
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
  });
}
