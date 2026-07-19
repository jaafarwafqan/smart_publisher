import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/post_entity.dart';

class CreatePost extends BaseUseCase<PostEntity, PostEntity> {
  const CreatePost();

  @override
  Future<AppResult<PostEntity>> call(PostEntity params) async {
    return Success<PostEntity>(params, message: 'Created');
  }
}
