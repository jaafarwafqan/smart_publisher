import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/domain/services/analytics_service.dart';
import 'package:smart_publisher/src/domain/publish_target.dart';
import 'package:smart_publisher/src/features/analytics/data/repository/analytics_repository_impl.dart';
import 'package:smart_publisher/src/features/analytics/domain/entities/analytics_metric_entity.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/create_post.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/schedule_post.dart';
import 'package:smart_publisher/src/publish_engine/engine/publish_engine.dart';

import '../helpers/fake_network_client.dart';

void main() {
  group('E2E - Content lifecycle', () {
    test('create -> schedule -> publish -> analytics report/export', () async {
      final postRepo = PostRepositoryImpl();
      final create = CreatePost(repository: postRepo);
      final schedule = SchedulePost(repository: postRepo);
      final engine = PublishEngine();

      final analyticsRepo = AnalyticsRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'message': 'ok',
                'data': <String, dynamic>{
                  'post_id': 'e2e-post-1',
                  'impressions': 1000,
                  'clicks': 120,
                  'shares': 40,
                  'reactions': 60,
                  'status': 'published',
                },
                'meta': <String, dynamic>{},
                'errors': <dynamic>[],
              },
            );
          },
        ),
      );
      final analytics = AnalyticsService(repository: analyticsRepo);

      final created = await create(
        const PostEntity(id: 'e2e-post-1', title: 'Title', body: 'Body'),
      );
      expect(created.isSuccess, isTrue);

      final scheduled = await schedule(
        PostEntity(
          id: created.data!.id,
          title: created.data!.title,
          body: created.data!.body,
          scheduledAt: DateTime.now().add(const Duration(minutes: 30)),
        ),
      );
      expect(scheduled.data?.status, 'scheduled');

      await engine.publish(
        post: scheduled.data!,
        targets: const <PublishTarget>[
          PublishTarget(
            category: PublishTargetCategory.social,
            destinationKey: 'facebook',
          ),
        ],
      );

      final metricsResult = await analytics.metrics('e2e-post-1');
      expect(metricsResult.isSuccess, isTrue);
      expect(metricsResult.data, isA<AnalyticsMetricEntity>());
      expect(metricsResult.data?.engagement, 220);

      final reportResult = await analytics.report(
        from: DateTime.now().subtract(const Duration(days: 7)),
        to: DateTime.now(),
        postIds: const <String>['e2e-post-1'],
      );
      expect(reportResult.isSuccess, isTrue);
      expect(reportResult.data?.items, isNotEmpty);

      final exportResult = await analytics.export(reportResult.data!);
      expect(exportResult.isSuccess, isTrue);
      expect(exportResult.data?.mimeType, 'text/csv');
      expect(exportResult.data?.content, contains('post_id,impressions'));
    });
  });
}
