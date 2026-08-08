import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/di/app_providers.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
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
}

OrganizationEntity _membership(
  String role, {
  int id = 1,
  bool isCurrent = true,
}) {
  return OrganizationEntity(
    id: id,
    name: 'Organization $id',
    slug: 'organization-$id',
    role: role,
    isCurrent: isCurrent,
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
  group('OrganizationRolePermissions', () {
    test(
      'matches the backend role templates and fails closed for unknown roles',
      () {
        final owner = OrganizationRolePermissions.forRole('owner');
        final admin = OrganizationRolePermissions.forRole('admin');
        final manager = OrganizationRolePermissions.forRole('manager');
        final editor = OrganizationRolePermissions.forRole('editor');
        final viewer = OrganizationRolePermissions.forRole('viewer');

        expect(owner, containsAll(OrganizationPermissions.all));
        expect(admin, contains(OrganizationPermissions.settingsManage));
        expect(
          admin,
          isNot(contains(OrganizationPermissions.organizationDelete)),
        );
        expect(
          admin,
          isNot(
            contains(OrganizationPermissions.organizationTransferOwnership),
          ),
        );

        expect(manager, contains(OrganizationPermissions.postsViewAll));
        expect(manager, contains(OrganizationPermissions.postsApprove));
        expect(manager, contains(OrganizationPermissions.postsPublish));
        expect(manager, contains(OrganizationPermissions.socialPagesManage));
        expect(
          manager,
          isNot(contains(OrganizationPermissions.settingsManage)),
        );

        expect(editor, contains(OrganizationPermissions.postsViewOwn));
        expect(editor, contains(OrganizationPermissions.postsCreate));
        expect(editor, contains(OrganizationPermissions.postsUpdateOwn));
        expect(editor, isNot(contains(OrganizationPermissions.postsViewAll)));
        expect(editor, isNot(contains(OrganizationPermissions.postsApprove)));
        expect(editor, isNot(contains(OrganizationPermissions.postsPublish)));

        expect(viewer, contains(OrganizationPermissions.postsViewAll));
        expect(viewer, isNot(contains(OrganizationPermissions.postsCreate)));
        expect(viewer, isNot(contains(OrganizationPermissions.postsPublish)));
        expect(OrganizationRolePermissions.forRole('unknown-role'), isEmpty);
      },
    );

    test('editor can request approval but cannot publish directly', () {
      final editor = OrganizationAccessState.active(
        memberships: <OrganizationEntity>[_membership('editor')],
        currentOrganization: _membership('editor'),
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
            _membership('owner', id: 1),
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
