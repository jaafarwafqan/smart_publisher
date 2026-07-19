import '../../features/posts/domain/entities/post_entity.dart';
import '../../platforms/core/platform_type.dart';

class PublishContext {
  const PublishContext({
    required this.post,
    required this.platforms,
    this.metadata = const {},
  });

  final PostEntity post;
  final List<PlatformType> platforms;
  final Map<String, Object?> metadata;
}
