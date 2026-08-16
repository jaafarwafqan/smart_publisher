import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/storage/storage_service.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';

import '../../helpers/fake_network_client.dart';

/// Same simulated on-disk backend as outbox_store_persistence_test.dart and
/// draft_storage_persistence_test.dart — state survives across separate
/// [AnalyticsRepositoryImpl] instances, the way flutter_secure_storage
/// survives an app restart.
class FakeStorageService implements StorageService {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

void main() {
  group('AnalyticsRepositoryImpl "last-viewed analytics" persistence', () {
    test(
      'a real fetch is still there after the repository is recreated (app restart)',
      () async {
        final backend = FakeStorageService();

        final beforeRestart = AnalyticsRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'post_id': '1',
                    'impressions': 500,
                    'clicks': 10,
                    'shares': 2,
                    'reactions': 8,
                    'comments': 1,
                    'reach': 300,
                    'available': true,
                    'status': 'published',
                  },
                },
              );
            },
          ),
          storage: backend,
        );
        await beforeRestart.getPostMetrics('1');

        // A fresh instance backed by the same storage, with NO network
        // client this time — represents the app being relaunched offline
        // right after the user last viewed this post's real numbers.
        final afterRestart = AnalyticsRepositoryImpl(storage: backend);
        final result = await afterRestart.getPostMetrics('1');

        expect(result.isSuccess, isTrue);
        final metric = result.data!;
        expect(metric.available, isTrue);
        expect(metric.impressions, 500);
        expect(metric.reach, 300);
        expect(metric.status, 'published');
      },
    );

    test(
      'without a storage backend, a fetch does NOT survive recreation (documents the gap this guards against)',
      () async {
        final beforeRestart = AnalyticsRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async => Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'post_id': '2',
                  'impressions': 99,
                  'clicks': 0,
                  'shares': 0,
                  'reactions': 0,
                  'comments': 0,
                  'reach': 50,
                  'available': true,
                  'status': 'published',
                },
              },
            ),
          ),
        );
        await beforeRestart.getPostMetrics('2');

        final afterRestart = AnalyticsRepositoryImpl();
        final result = await afterRestart.getPostMetrics('2');

        // No prior data and no network client: falls back to an honest
        // zeroed/unavailable placeholder, not the earlier session's numbers.
        expect(result.data!.available, isFalse);
        expect(result.data!.impressions, 0);
      },
    );

    test(
      'a bulk fetch persists every metric, not just the last one written',
      () async {
        final backend = FakeStorageService();

        final beforeRestart = AnalyticsRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async => Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'post_id': 'a',
                    'impressions': 10,
                    'clicks': 0,
                    'shares': 0,
                    'reactions': 0,
                    'comments': 0,
                    'reach': 5,
                    'available': true,
                    'status': 'published',
                  },
                  <String, dynamic>{
                    'post_id': 'b',
                    'impressions': 20,
                    'clicks': 0,
                    'shares': 0,
                    'reactions': 0,
                    'comments': 0,
                    'reach': 15,
                    'available': true,
                    'status': 'published',
                  },
                ],
              },
            ),
          ),
          storage: backend,
        );
        await beforeRestart.getPostsMetrics(['a', 'b']);

        final afterRestart = AnalyticsRepositoryImpl(storage: backend);
        final result = await afterRestart.getPostsMetrics(['a', 'b']);

        final byId = {for (final m in result.data!) m.postId: m};
        expect(byId['a']!.impressions, 10);
        expect(byId['b']!.impressions, 20);
      },
    );

    test(
      'a single fetch does not erase a different post already persisted',
      () async {
        final backend = FakeStorageService();

        Response<dynamic> respond(String postId, int impressions) {
          return Response<dynamic>(
            requestOptions: RequestOptions(path: ''),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'post_id': postId,
                'impressions': impressions,
                'clicks': 0,
                'shares': 0,
                'reactions': 0,
                'comments': 0,
                'reach': 0,
                'available': true,
                'status': 'published',
              },
            },
          );
        }

        final first = AnalyticsRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async => respond('x', 100),
          ),
          storage: backend,
        );
        await first.getPostMetrics('x');

        final second = AnalyticsRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async => respond('y', 200),
          ),
          storage: backend,
        );
        await second.getPostMetrics('y');

        final third = AnalyticsRepositoryImpl(storage: backend);
        final x = await third.getPostMetrics('x');
        final y = await third.getPostMetrics('y');

        expect(x.data!.impressions, 100);
        expect(y.data!.impressions, 200);
      },
    );

    test(
      'corrupted persisted state is discarded rather than crashing startup',
      () async {
        final backend = FakeStorageService();
        await backend.writeString(
          'analytics_last_viewed_v1',
          'not valid json {{{',
        );

        final repository = AnalyticsRepositoryImpl(storage: backend);
        final result = await repository.getPostMetrics('z');

        expect(result.isSuccess, isTrue);
        expect(result.data!.available, isFalse);
      },
    );
  });
}
