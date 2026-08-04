import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/network/network_interceptor.dart';
import 'package:smart_publisher/src/core/storage/in_memory_storage_service.dart';
import 'package:smart_publisher/src/core/tenancy/active_organization_store.dart';

void main() {
  group('OrganizationHeaderInterceptor', () {
    test(
      'adds X-Organization-Id when an active organization is stored',
      () async {
        final store = ActiveOrganizationStore(
          storage: InMemoryStorageService(),
        );
        await store.write(42);
        final interceptor = OrganizationHeaderInterceptor(store: store);
        final options = RequestOptions(path: '/posts');

        final handler = _CapturingRequestHandler();
        await interceptor.onRequest(options, handler);

        expect(handler.nextCalled, isTrue);
        expect(options.headers['X-Organization-Id'], '42');
      },
    );

    test('sends no header at all when nothing has been selected yet', () async {
      final store = ActiveOrganizationStore(storage: InMemoryStorageService());
      final interceptor = OrganizationHeaderInterceptor(store: store);
      final options = RequestOptions(path: '/posts');

      final handler = _CapturingRequestHandler();
      await interceptor.onRequest(options, handler);

      expect(handler.nextCalled, isTrue);
      expect(options.headers.containsKey('X-Organization-Id'), isFalse);
    });
  });
}

class _CapturingRequestHandler extends RequestInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(
    RequestOptions requestOptions, {
    bool? callFollowingErrorInterceptor,
  }) {
    nextCalled = true;
  }
}
