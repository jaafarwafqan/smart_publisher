import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class CreatePost extends BaseUseCase<PostEntity, PostEntity> {
  const CreatePost({required this.repository});

  final PostRepository repository;

  @override
  Future<AppResult<PostEntity>> call(PostEntity params) {
    return repository.createPost(params);
  }
}
