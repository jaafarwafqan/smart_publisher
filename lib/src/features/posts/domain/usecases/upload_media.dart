import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/media_entity.dart';

class UploadMedia extends BaseUseCase<MediaEntity, MediaEntity> {
  const UploadMedia();

  @override
  Future<AppResult<MediaEntity>> call(MediaEntity params) async {
    return Success<MediaEntity>(params, message: 'Media uploaded');
  }
}
