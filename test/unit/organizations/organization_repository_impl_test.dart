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
  });
}
