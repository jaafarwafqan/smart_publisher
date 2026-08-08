import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/tenancy/active_organization_store.dart';
import 'package:smart_publisher/src/features/organizations/data/organization_repository_impl.dart';

import '../../helpers/fake_network_client.dart';

void main() {
  group('OrganizationRepositoryImpl', () {
    test('getMyOrganizations maps the backend list into entities', () async {
      final store = ActiveOrganizationStore(storage: InMemoryStorageService());
      final client = FakeNetworkClient(
        getHandler: (path) async {
          expect(path, '/organizations');
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'message': 'OK',
              'data': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 1,
                  'name': "Ada's Organization",
                  'slug': 'ada-org',
                  'role': 'owner',
                  'is_current': true,
                },
                <String, dynamic>{
                  'id': 2,
                  'name': 'Shared Workspace',
                  'slug': 'shared-workspace',
                  'role': 'editor',
                  'is_current': false,
                },
              ],
              'meta': <String, dynamic>{},
              'errors': null,
            },
          );
        },
      );

      final repository = OrganizationRepositoryImpl(
        networkClient: client,
        store: store,
      );

      final result = await repository.getMyOrganizations();

      expect(result.isSuccess, isTrue);
      final orgs = result.data!;
      expect(orgs, hasLength(2));
      expect(orgs[0].id, 1);
      expect(orgs[0].role, 'owner');
      expect(orgs[0].isCurrent, isTrue);
      expect(orgs[1].id, 2);
      expect(orgs[1].role, 'editor');
      expect(orgs[1].isCurrent, isFalse);
    });

    test(
      'switchTo persists the new active organization id only after a successful response',
      () async {
        final storage = InMemoryStorageService();
        final store = ActiveOrganizationStore(storage: storage);
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            expect(path, '/organizations/2/switch');
            return Response(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'message': 'Active organization switched.',
                'data': <String, dynamic>{
                  'id': 2,
                  'name': 'Shared Workspace',
                  'slug': 'shared-workspace',
                  'role': 'manager',
                },
                'meta': <String, dynamic>{},
                'errors': null,
              },
            );
          },
        );

        final repository = OrganizationRepositoryImpl(
          networkClient: client,
          store: store,
        );

        expect(await store.read(), isNull);

        final result = await repository.switchTo(2);

        expect(result.isSuccess, isTrue);
        expect(result.data!.role, 'manager');
        expect(await store.read(), 2);
      },
    );

    test(
      'switchTo does not persist anything locally when the backend rejects the switch',
      () async {
        final storage = InMemoryStorageService();
        final store = ActiveOrganizationStore(storage: storage);
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            return Response(
              requestOptions: RequestOptions(path: path),
              statusCode: 403,
              data: <String, dynamic>{
                'success': false,
                'message': 'You are not a member of this organization.',
                'data': null,
                'meta': <String, dynamic>{},
                'errors': <String, dynamic>{},
              },
            );
          },
        );

        final repository = OrganizationRepositoryImpl(
          networkClient: client,
          store: store,
        );

        final result = await repository.switchTo(999);

        expect(result.isSuccess, isFalse);
        expect(await store.read(), isNull);
      },
    );

    test('getMembers maps the backend list into member entities', () async {
      final store = ActiveOrganizationStore(storage: InMemoryStorageService());
      final client = FakeNetworkClient(
        getHandler: (path) async {
          expect(path, '/organization/members');
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'message': 'OK',
              'data': <Map<String, dynamic>>[
                <String, dynamic>{
                  'user_id': 1,
                  'name': 'Ada Lovelace',
                  'email': 'ada@example.com',
                  'role': 'owner',
                },
                <String, dynamic>{
                  'user_id': 2,
                  'name': 'Grace Hopper',
                  'email': 'grace@example.com',
                  'role': 'editor',
                },
              ],
              'meta': <String, dynamic>{},
              'errors': null,
            },
          );
        },
      );

      final repository = OrganizationRepositoryImpl(
        networkClient: client,
        store: store,
      );

      final result = await repository.getMembers();

      expect(result.isSuccess, isTrue);
      final members = result.data!;
      expect(members, hasLength(2));
      expect(members[0].userId, 1);
      expect(members[0].role, 'owner');
      expect(members[1].email, 'grace@example.com');
    });

    test(
      'addMember posts the email and role and returns the new member',
      () async {
        final store = ActiveOrganizationStore(
          storage: InMemoryStorageService(),
        );
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            expect(path, '/organization/members');
            expect(data, <String, dynamic>{
              'email': 'new@example.com',
              'role': 'editor',
            });
            return Response(
              requestOptions: RequestOptions(path: path),
              statusCode: 201,
              data: <String, dynamic>{
                'success': true,
                'message': 'Member added.',
                'data': <String, dynamic>{
                  'user_id': 5,
                  'name': 'New Member',
                  'email': 'new@example.com',
                  'role': 'editor',
                },
                'meta': <String, dynamic>{},
                'errors': null,
              },
            );
          },
        );

        final repository = OrganizationRepositoryImpl(
          networkClient: client,
          store: store,
        );

        final result = await repository.addMember(
          email: 'new@example.com',
          role: 'editor',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.userId, 5);
        expect(result.data!.name, 'New Member');
      },
    );

    test('addMember surfaces a quota-exceeded failure', () async {
      final store = ActiveOrganizationStore(storage: InMemoryStorageService());
      final client = FakeNetworkClient(
        postHandler: (path, data) async {
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 422,
            data: <String, dynamic>{
              'success': false,
              'message': 'Validation failed.',
              'data': null,
              'meta': <String, dynamic>{},
              'errors': <String, dynamic>{
                'email': <String>[
                  'Your organization has reached its team member limit for the current plan.',
                ],
              },
            },
          );
        },
      );

      final repository = OrganizationRepositoryImpl(
        networkClient: client,
        store: store,
      );

      final result = await repository.addMember(
        email: 'over-limit@example.com',
        role: 'viewer',
      );

      expect(result.isSuccess, isFalse);
    });

    test('updateMemberRole puts the new role for the given user', () async {
      final store = ActiveOrganizationStore(storage: InMemoryStorageService());
      final client = FakeNetworkClient(
        putHandler: (path, data) async {
          expect(path, '/organization/members/5');
          expect(data, <String, dynamic>{'role': 'manager'});
          // A distinct echoed role ('MANAGER', uppercase) proves the
          // returned entity's role field is actually parsed from the
          // response body, not just falling back to the request's own
          // `role` parameter.
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'message': 'Member role updated.',
              'data': <String, dynamic>{'user_id': 5, 'role': 'MANAGER'},
              'meta': <String, dynamic>{},
              'errors': null,
            },
          );
        },
      );

      final repository = OrganizationRepositoryImpl(
        networkClient: client,
        store: store,
      );

      final result = await repository.updateMemberRole(
        userId: 5,
        role: 'manager',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.userId, 5);
      expect(result.data!.role, 'MANAGER');
    });

    test('removeMember deletes the member by id', () async {
      final store = ActiveOrganizationStore(storage: InMemoryStorageService());
      var deletedPath = '';
      final client = FakeNetworkClient(
        deleteHandler: (path, data) async {
          deletedPath = path;
          return Response(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{'message': 'Member removed.'},
          );
        },
      );

      final repository = OrganizationRepositoryImpl(
        networkClient: client,
        store: store,
      );

      final result = await repository.removeMember(userId: 7);

      expect(result.isSuccess, isTrue);
      expect(deletedPath, '/organization/members/7');
    });
  });
}
