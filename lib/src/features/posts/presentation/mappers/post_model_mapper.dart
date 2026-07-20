import '../../domain/entities/post_entity.dart';
import '../models/post_model.dart';

class PostModelMapper {
  const PostModelMapper();

  PostModel toModel(PostEntity entity) {
    return PostModel(
      id: entity.id,
      title: entity.title,
      body: entity.body,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      aiImproved: entity.aiImproved,
      hasMedia: entity.hasMedia,
      scheduledAt: entity.scheduledAt,
      attachments: entity.attachments,
      platforms: entity.platforms,
    );
  }

  PostEntity toEntity(PostModel model) {
    return PostEntity(
      id: model.id,
      title: model.title,
      body: model.body,
      status: model.status,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      aiImproved: model.aiImproved,
      hasMedia: model.hasMedia,
      scheduledAt: model.scheduledAt,
      attachments: model.attachments,
      platforms: model.platforms,
    );
  }
}
