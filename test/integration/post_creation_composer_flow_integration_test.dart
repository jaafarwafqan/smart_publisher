import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/domain/publish_target.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/create_post.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/schedule_post.dart';
import 'package:smart_publisher/src/publish_engine/engine/publish_engine.dart';

void main() {
  group('Integration - Post Creation Composer Flow', () {
    test('create with media/platforms then schedule and publish', () async {
      final repository = PostRepositoryImpl();
      final createPost = CreatePost(repository: repository);
      final schedulePost = SchedulePost(repository: repository);
      final publishEngine = PublishEngine();

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

      await publishEngine.publish(
        post: created.data!,
        targets: const <PublishTarget>[
          PublishTarget(
            category: PublishTargetCategory.social,
            destinationKey: 'facebook',
          ),
          PublishTarget(
            category: PublishTargetCategory.professional,
            destinationKey: 'linkedin',
          ),
        ],
      );

      final job = await publishEngine.queueManager.findById(created.data!.id);
      expect(job?.status.name, 'succeeded');
    });
  });
}
