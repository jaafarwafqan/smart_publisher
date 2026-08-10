import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/create_post.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/schedule_post.dart';
import 'package:smart_publisher/src/features/schedule/data/schedule_repository_impl.dart';

import '../helpers/fake_network_client.dart';

void main() {
  group('Integration - Post Creation Composer Flow', () {
    test('create with media/platforms then schedule', () async {
      final repository = PostRepositoryImpl();
      final createPost = CreatePost(repository: repository);
      final scheduleRepo = ScheduleRepositoryImpl(
        networkClient: FakeNetworkClient(
          postHandler: (path, data) async {
            final body = data as Map<String, dynamic>;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'id': 'composer-flow-1',
                'title': 'Campaign: Summer Launch',
                'content': 'New features are live. Check them out today.',
                'status': 'scheduled',
                'scheduled_at': body['scheduled_at'],
                'attachments': <String>[
                  'https://cdn.smartpublisher.local/media/post-1-image.png',
                  'https://cdn.smartpublisher.local/media/post-1-video.mp4',
                ],
                'platforms': <String>['facebook', 'linkedin'],
              },
            );
          },
        ),
      );
      final schedulePost = SchedulePost(repository: scheduleRepo);

      final draft = PostEntity(
        id: 'composer-flow-1',
        title: 'Campaign: Summer Launch',
        body: 'New features are live. Check them out today.',
        hasMedia: true,
        attachments: const <String>[
          'https://cdn.smartpublisher.local/media/post-1-image.png',
          'https://cdn.smartpublisher.local/media/post-1-video.mp4',
        ],
        platforms: const <String>['facebook', 'linkedin'],
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      );

      final created = await createPost(draft);
      expect(created.isSuccess, isTrue);
      expect(created.data, isNotNull);
      expect(created.data!.attachments.length, 2);
      expect(
        created.data!.platforms,
        containsAll(<String>['facebook', 'linkedin']),
      );

      final scheduled = await schedulePost(
        created.data!.copyWith(
          status: 'scheduled',
          scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      );

      expect(scheduled.isSuccess, isTrue);
      expect(scheduled.data, isNotNull);
      expect(scheduled.data!.status, 'scheduled');
      expect(scheduled.data!.scheduledAt, isNotNull);
    });
  });
}
