import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/domain/publish_target.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/create_post.dart';
import 'package:smart_publisher/src/publish_engine/engine/publish_engine.dart';

void main() {
  group('Integration - Publish Flow', () {
    test('create post then publish through engine', () async {
      final postRepository = PostRepositoryImpl();
      final createPost = CreatePost(repository: postRepository);
      final engine = PublishEngine();

      const post = PostEntity(
        id: 'int-publish-1',
        title: 'Title',
        body: 'Body',
      );
      final created = await createPost(post);
      expect(created.isSuccess, isTrue);

      await engine.publish(
        post: created.data!,
        targets: const <PublishTarget>[
          PublishTarget(
            category: PublishTargetCategory.social,
            destinationKey: 'facebook',
          ),
        ],
      );

      final job = await engine.queueManager.findById(post.id);
      expect(job?.status.name, 'succeeded');
    });
  });
}
