import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';

import '../../helpers/fake_network_client.dart';

void main() {
  group('AnalyticsRepositoryImpl.getSummary', () {
    test('parses the real /analytics summary shape', () async {
      final repository = AnalyticsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'total_posts': 145,
                  'published': 120,
                  'failed': 4,
                  'scheduled': 21,
                  'draft': 0,
                  'engagement': <String, dynamic>{'score': 0.82, 'trend': 'up'},
                  'updated_at': '2026-06-15T12:00:00Z',
                },
              },
            );
          },
        ),
      );

      final result = await repository.getSummary();

      expect(result.isSuccess, isTrue);
      final summary = result.data!;
      expect(summary.totalPosts, 145);
      expect(summary.published, 120);
      expect(summary.failed, 4);
      expect(summary.scheduled, 21);
      expect(summary.draft, 0);
      expect(summary.engagementScore, 0.82);
      expect(summary.engagementTrend, 'up');
    });

    test('builds a local zeroed summary without a network client', () async {
      final repository = AnalyticsRepositoryImpl();

      final result = await repository.getSummary();

      expect(result.isSuccess, isTrue);
      expect(result.data!.totalPosts, 0);
      expect(result.data!.engagementTrend, 'stable');
    });
  });

  group('AnalyticsRepositoryImpl.getPostsMetrics', () {
    test('parses a bulk list of real per-post metrics in one call', () async {
      String? requestedPath;

      final repository = AnalyticsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            requestedPath = path;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'post_id': '1',
                    'impressions': 500,
                    'clicks': 20,
                    'shares': 5,
                    'reactions': 10,
                    'comments': 3,
                    'reach': 400,
                    'available': true,
                    'status': 'published',
                  },
                  <String, dynamic>{
                    'post_id': '2',
                    'impressions': 0,
                    'clicks': 0,
                    'shares': 0,
                    'reactions': 0,
                    'comments': 0,
                    'reach': 0,
                    'available': false,
                    'status': 'draft',
                  },
                ],
              },
            );
          },
        ),
      );

      final result = await repository.getPostsMetrics(['1', '2']);

      expect(result.isSuccess, isTrue);
      expect(requestedPath, contains('/analytics/posts'));
      expect(requestedPath, contains('post_ids[]=1'));
      expect(requestedPath, contains('post_ids[]=2'));

      final metrics = result.data!;
      expect(metrics.length, 2);
      final first = metrics.firstWhere((m) => m.postId == '1');
      expect(first.available, isTrue);
      expect(first.reach, 400);
      expect(first.engagement, 20 + 5 + 10 + 3);
      final second = metrics.firstWhere((m) => m.postId == '2');
      expect(second.available, isFalse);
    });

    test(
      'builds local zeroed/unavailable metrics without a network client',
      () async {
        final repository = AnalyticsRepositoryImpl();

        final result = await repository.getPostsMetrics(['1', '2']);

        expect(result.isSuccess, isTrue);
        expect(result.data!.length, 2);
        expect(result.data!.every((m) => !m.available), isTrue);
      },
    );
  });

  group('AnalyticsRepositoryImpl.getDashboard', () {
    test('parses best_platform and best_publish_hour when present', () async {
      final repository = AnalyticsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'top_posts': <dynamic>[],
                  'total_reach': 100,
                  'total_engagement': 10,
                  'total_impressions': 200,
                  'average_engagement_rate': 0.1,
                  'best_platform': 'facebook',
                  'best_publish_hour': 14,
                },
              },
            );
          },
        ),
      );

      final result = await repository.getDashboard();

      expect(result.isSuccess, isTrue);
      expect(result.data!.bestPlatform, 'facebook');
      expect(result.data!.bestPublishHour, 14);
    });

    test(
      'reports null best_platform/best_publish_hour honestly when absent',
      () async {
        final repository = AnalyticsRepositoryImpl(
          networkClient: FakeNetworkClient(
            getHandler: (path) async {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'top_posts': <dynamic>[],
                    'total_reach': 0,
                    'total_engagement': 0,
                    'total_impressions': 0,
                    'average_engagement_rate': 0.0,
                    'best_platform': null,
                    'best_publish_hour': null,
                  },
                },
              );
            },
          ),
        );

        final result = await repository.getDashboard();

        expect(result.isSuccess, isTrue);
        expect(result.data!.bestPlatform, isNull);
        expect(result.data!.bestPublishHour, isNull);
      },
    );
  });
}
