import '../../features/posts/data/media_dto.dart';
import '../../features/posts/domain/entities/media_entity.dart';
import '../../shared/mappers/mapper.dart';

class MediaMapper extends Mapper<MediaDto, MediaEntity> {
  const MediaMapper();

  @override
  MediaEntity map(MediaDto input) {
    return MediaEntity(
      id: input.id,
      postId: input.postId,
      url: input.url,
      mimeType: input.mimeType,
      sizeInBytes: input.sizeInBytes,
      isCompressed: input.isCompressed,
    );
  }
}
