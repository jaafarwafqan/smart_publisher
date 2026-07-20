import '../../backend_contracts/v1/posts_contract_v1.dart';
import '../../features/posts/domain/entities/post_entity.dart';
import '../../shared/mappers/mapper.dart';

class PostMapper extends Mapper<PostResponseDtoV1, PostEntity> {
  const PostMapper();

  @override
  PostEntity map(PostResponseDtoV1 input) {
    return PostEntity(
      id: input.id,
      title: input.title,
      body: input.content,
      status: input.status,
      createdAt: input.createdAt,
      updatedAt: input.updatedAt,
      aiImproved: false,
      hasMedia: false,
      scheduledAt: input.scheduledAt,
    );
  }
}
