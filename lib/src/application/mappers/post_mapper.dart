import '../../features/posts/data/post_dto.dart';
import '../../features/posts/domain/entities/post_entity.dart';
import '../../shared/mappers/mapper.dart';

class PostMapper extends Mapper<PostDto, PostEntity> {
  const PostMapper();

  @override
  PostEntity map(PostDto input) {
    return PostEntity(
      id: input.id,
      title: input.title,
      body: input.body,
      status: input.status,
      createdAt: input.createdAt,
      updatedAt: input.updatedAt,
      aiImproved: input.aiImproved,
      hasMedia: input.hasMedia,
      scheduledAt: input.scheduledAt,
    );
  }
}
