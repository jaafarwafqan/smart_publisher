import '../../features/posts/domain/entities/post_entity.dart';
import '../../platforms/core/platform_type.dart';
import '../../publish_engine/engine/publish_engine.dart';

class PublishService {
  const PublishService(this.publishEngine);

  final PublishEngine publishEngine;

  Future<void> publishPost({
    required PostEntity post,
    required List<PlatformType> platforms,
  }) async {
    await publishEngine.publish(post: post, platforms: platforms);
  }
}
