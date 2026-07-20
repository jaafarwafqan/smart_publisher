import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../../../media/domain/repositories/media_repository.dart';
import '../entities/media_entity.dart';

class CompressMedia extends BaseUseCase<MediaEntity, MediaEntity> {
  const CompressMedia({required this.repository});

  final MediaRepository repository;

  @override
  Future<AppResult<MediaEntity>> call(MediaEntity params) {
    return repository.compressMedia(params);
  }
}
