import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/post_entity.dart';

abstract class PostRepository extends BaseRepository<PostEntity> {
  const PostRepository();

  Future<AppResult<PostEntity>> createPost(PostEntity post);
  Future<AppResult<PostEntity>> updatePost(PostEntity post);
  Future<AppResult<PostEntity>> getPost(String id);
  Future<AppResult<List<PostEntity>>> getPosts();
  Future<AppResult<void>> deletePost(String id);
}
