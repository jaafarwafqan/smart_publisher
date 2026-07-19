import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../../../posts/domain/entities/media_entity.dart';

abstract class MediaRepository extends BaseRepository<MediaEntity> {
  const MediaRepository();

  Future<AppResult<MediaEntity>> uploadMedia(MediaEntity media);
  Future<AppResult<MediaEntity>> compressMedia(MediaEntity media);
  Future<AppResult<void>> deleteMedia(String id);
}
