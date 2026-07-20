import '../../features/posts/domain/entities/post_entity.dart';
import '../../domain/publish_target.dart';

class PublishContext {
  const PublishContext({
    required this.post,
    required this.targets,
    this.metadata = const {},
  });

  final PostEntity post;
  final List<PublishTarget> targets;
  final Map<String, Object?> metadata;
}
