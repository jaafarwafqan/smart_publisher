import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/media_entity.dart';

class CompressMedia extends BaseUseCase<MediaEntity, MediaEntity> {
  const CompressMedia();

  @override
  Future<AppResult<MediaEntity>> call(MediaEntity params) async {
    return Success<MediaEntity>(params, message: 'Media compressed');
  }
}
