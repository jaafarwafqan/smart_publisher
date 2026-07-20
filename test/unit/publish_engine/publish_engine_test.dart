import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/domain/publish_target.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/publish_engine/engine/publish_engine.dart';

void main() {
  group('PublishEngine', () {
    test('publishes job successfully for a valid target', () async {
      final engine = PublishEngine();
      const post = PostEntity(id: 'post-1', title: 'Title', body: 'Body');

      await engine.publish(
        post: post,
        targets: const <PublishTarget>[
          PublishTarget(
            category: PublishTargetCategory.social,
            destinationKey: 'facebook',
          ),
        ],
      );

      final job = await engine.queueManager.findById(post.id);
      expect(job, isNotNull);
      expect(job?.status.name, 'succeeded');
    });
  });
}
