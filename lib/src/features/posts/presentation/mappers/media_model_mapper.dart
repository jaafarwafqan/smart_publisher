import '../../domain/entities/media_entity.dart';
import '../models/media_model.dart';

class MediaModelMapper {
  const MediaModelMapper();

  MediaModel toModel(MediaEntity entity) {
    return MediaModel(
      id: entity.id,
      postId: entity.postId,
      url: entity.url,
      mimeType: entity.mimeType,
      sizeInBytes: entity.sizeInBytes,
      isCompressed: entity.isCompressed,
    );
  }

  MediaEntity toEntity(MediaModel model) {
    return MediaEntity(
      id: model.id,
      postId: model.postId,
      url: model.url,
      mimeType: model.mimeType,
      sizeInBytes: model.sizeInBytes,
      isCompressed: model.isCompressed,
    );
  }
}
