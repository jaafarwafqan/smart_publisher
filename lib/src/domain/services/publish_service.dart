import '../../features/posts/domain/entities/post_entity.dart';
import '../publish_target.dart';
import '../../publish_engine/engine/publish_engine.dart';

class PublishService {
  const PublishService(this.publishEngine);

  final PublishEngine publishEngine;

  Future<void> publishPost({
    required PostEntity post,
    required List<PublishTarget> targets,
  }) async {
    await publishEngine.publish(post: post, targets: targets);
  }
}
