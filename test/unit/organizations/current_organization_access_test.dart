import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/base/pagination.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/shared/models/audit_log_entry.dart';
import 'package:smart_publisher/src/core/storage/storage_provider.dart';
import 'package:smart_publisher/src/features/organizations/application/current_organization_access.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_entity.dart';
import 'package:smart_publisher/src/features/organizations/domain/entities/organization_member_entity.dart';
import 'package:smart_publisher/src/features/organizations/domain/repositories/organization_repository.dart';

class _FakeOrganizationRepository implements OrganizationRepository {
  _FakeOrganizationRepository(this.getter);

  final Future<AppResult<List<OrganizationEntity>>> Function() getter;

  @override
  Future<AppResult<List<OrganizationEntity>>> getMyOrganizations() => getter();

  @override
  Future<AppResult<OrganizationEntity>> switchTo(int organizationId) {
    return Future<AppResult<OrganizationEntity>>.value(
      const Failure<OrganizationEntity>('Not implemented for this test.'),
    );
  }

  @override
  Future<AppResult<List<OrganizationMemberEntity>>> getMembers() {
    return Future<AppResult<List<OrganizationMemberEntity>>>.value(
      const Failure<List<OrganizationMemberEntity>>(
        'Not implemented for this test.',
      ),
    );
  }

  @override
  Future<AppResult<OrganizationMemberEntity>> addMember({
    required String email,
    required String role,
  }) {
    return Future<AppResult<OrganizationMemberEntity>>.value(
      const Failure<OrganizationMemberEntity>('Not implemented for this test.'),
    );
  }

  @override
  Future<AppResult<OrganizationMemberEntity>> updateMemberRole({
    required int userId,
    required String role,
  }) {
    return Future<AppResult<OrganizationMemberEntity>>.value(
      const Failure<OrganizationMemberEntity>('Not implemented for this test.'),
    );
  }

  @override
  Future<AppResult<void>> removeMember({required int userId}) {
    return Future<AppResult<void>>.value(
      const Failure<void>('Not implemented for this test.'),
    );
  }

  @override
  Future<AppResult<PaginatedResult<AuditLogEntry>>> getAuditLogs({
    required int organizationId,
    int page = 1,
    int perPage = 25,
    String? action,
    String? dateFrom,
    String? dateTo,
  }) {
    return Future<AppResult<PaginatedResult<AuditLogEntry>>>.value(
      const Failure<PaginatedResult<AuditLogEntry>>(
        'Not implemented for this test.',
      ),
    );
  }
}

// Sprint E (role/permission remediation): the backend now resolves and
// sends the permission set directly (see OrganizationMembershipDtoV1), so a
// test fixture must supply it explicitly instead of relying on a client-side
// role-to-permissions map (OrganizationRolePermissions, now deleted). These
// callers simulate exactly what GET /organizations would send for the named
// role, matching App\Enums\OrganizationRole::permissions() on the backend.
OrganizationEntity _membership(
  String role, {
  int id = 1,
  bool isCurrent = true,
  Set<String> permissions = const <String>{},
}) {
  return OrganizationEntity(
    id: id,
    name: 'Organization $id',
    slug: 'organization-$id',
    role: role,
    isCurrent: isCurrent,
    permissions: permissions,
  );
}

ProviderContainer _containerFor(_FakeOrganizationRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      organizationRepositoryProvider.overrideWithValue(repository),
      storageServiceProvider.overrideWithValue(InMemoryStorageService()),
    ],
  );
}

void main() {
  group('OrganizationAccessState', () {
    test(
      'active() exposes exactly the permissions the backend sent, nothing derived locally',
      () {
        final owner = OrganizationAccessState.active(
          memberships: <OrganizationEntity>[_membership('owner')],
          currentOrganization: _membership(
            'owner',
            permissions: OrganizationPermissions.all,
          ),
        );
        expect(
          owner.hasPermission(OrganizationPermissions.organizationDelete),
          isTrue,
        );

        final viewer = OrganizationAccessState.active(
          memberships: <OrganizationEntity>[_membership('viewer')],
          currentOrganization: _membership(
            'viewer',
            permissions: const <String>{
              OrganizationPermissions.postsViewAll,
              OrganizationPermissions.socialAccountsView,
            },
          ),
        );
        expect(
          viewer.hasPermission(OrganizationPermissions.postsViewAll),
          isTrue,
        );
        expect(
          viewer.hasPermission(OrganizationPermissions.postsCreate),
          isFalse,
        );
        expect(
          viewer.hasPermission(OrganizationPermissions.socialAccountsConnect),
          isFalse,
        );

        // An unrecognized/empty permission set (e.g. a role the client
        // doesn't know how to label yet) must fail closed — no permission
        // granted — never fall back to guessing from the role name.
        final unknown = OrganizationAccessState.active(
          memberships: <OrganizationEntity>[_membership('mystery-role')],
          currentOrganization: _membership('mystery-role'),
        );
        expect(unknown.hasAnyPermission(OrganizationPermissions.all), isFalse);
      },
    );

    test('editor can request approval but cannot publish directly', () {
      final editorMembership = _membership(
        'editor',
        permissions: const <String>{
          OrganizationPermissions.postsCreate,
          OrganizationPermissions.postsRequestApproval,
          OrganizationPermissions.postsUpdateOwn,
        },
      );
      final editor = OrganizationAccessState.active(
        memberships: <OrganizationEntity>[editorMembership],
        currentOrganization: editorMembership,
      );

      expect(editor.canRequestPostApproval, isTrue);
      expect(editor.canPublishOrRequestApproval, isTrue);
      expect(
        editor.hasPermission(OrganizationPermissions.postsPublish),
        isFalse,
      );
      expect(
        editor.hasPermission(OrganizationPermissions.postsApprove),
        isFalse,
      );
    });
  });

  group('currentOrganizationAccessProvider', () {
    test(
      'uses the current membership returned by the API and hydrates its header hint',
      () async {
        final repository = _FakeOrganizationRepository(
          () async => Success<List<OrganizationEntity>>(<OrganizationEntity>[
            _membership(
              'owner',
              id: 1,
              permissions: const <String>{OrganizationPermissions.postsPublish},
            ),
            _membership('editor', id: 2, isCurrent: false),
          ]),
        );
        final container = _containerFor(repository);
        addTearDown(container.dispose);

        final access = await container.read(
          currentOrganizationAccessProvider.future,
        );

        expect(access.currentOrganization?.id, 1);
        expect(
          access.hasPermission(OrganizationPermissions.postsPublish),
          isTrue,
        );
        expect(await container.read(activeOrganizationStoreProvider).read(), 1);
      },
    );

    test(
      'clears a stale active organization when the API has no current membership',
      () async {
        final repository = _FakeOrganizationRepository(
          () async => Success<List<OrganizationEntity>>(<OrganizationEntity>[
            _membership('viewer', id: 7, isCurrent: false),
          ]),
        );
        final container = _containerFor(repository);
        addTearDown(container.dispose);
        await container.read(activeOrganizationStoreProvider).write(99);

        final access = await container.read(
          currentOrganizationAccessProvider.future,
        );

        expect(access.hasMemberships, isTrue);
        expect(access.hasActiveOrganization, isFalse);
        expect(
          access.hasPermission(OrganizationPermissions.postsViewAll),
          isFalse,
        );
        expect(
          await container.read(activeOrganizationStoreProvider).read(),
          isNull,
        );
      },
    );

    test(
      'surfaces a membership loading failure instead of returning an empty state',
      () async {
        final repository = _FakeOrganizationRepository(
          () async => const Failure<List<OrganizationEntity>>(
            'Organization API is unavailable.',
          ),
        );
        final container = _containerFor(repository);
        addTearDown(container.dispose);

        await expectLater(
          container.read(currentOrganizationAccessProvider.future),
          throwsA(
            isA<OrganizationAccessException>().having(
              (error) => error.message,
              'message',
              'Organization API is unavailable.',
            ),
          ),
        );
      },
    );

    test(
      'is loading until the organization membership response arrives',
      () async {
        final response = Completer<AppResult<List<OrganizationEntity>>>();
        final container = _containerFor(
          _FakeOrganizationRepository(() => response.future),
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          currentOrganizationAccessProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(subscription.close);

        expect(
          container.read(currentOrganizationAccessProvider).isLoading,
          isTrue,
        );

        response.complete(
          Success<List<OrganizationEntity>>(<OrganizationEntity>[
            _membership('manager'),
          ]),
        );
        final access = await container.read(
          currentOrganizationAccessProvider.future,
        );
        expect(access.currentOrganization?.role, 'manager');
      },
    );
  });
}
