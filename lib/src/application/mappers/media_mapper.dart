import '../../backend_contracts/v1/media_contract_v1.dart';
import '../../features/posts/domain/entities/media_entity.dart';
import '../../shared/mappers/mapper.dart';

class MediaMapper extends Mapper<MediaResponseDtoV1, MediaEntity> {
  const MediaMapper();

  @override
  MediaEntity map(MediaResponseDtoV1 input) {
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
