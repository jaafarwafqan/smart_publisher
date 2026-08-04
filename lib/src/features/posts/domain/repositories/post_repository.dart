import '../../../../core/base/base_repository.dart';
import '../../../../core/base/pagination.dart';
import '../../../../core/result/app_result.dart';
import '../entities/post_entity.dart';

abstract class PostRepository extends BaseRepository<PostEntity> {
  const PostRepository();

  Future<AppResult<PostEntity>> createPost(PostEntity post);
  Future<AppResult<PostEntity>> updatePost(PostEntity post);
  Future<AppResult<PostEntity>> getPost(String id);

  /// Unpaginated convenience — used by callers (analytics, composer) that
  /// genuinely need every post. [getPostsPage] is what the posts list
  /// screen uses so users with more than one backend page of posts aren't
  /// silently capped at the first page's worth.
  Future<AppResult<List<PostEntity>>> getPosts();

  Future<AppResult<PaginatedResult<PostEntity>>> getPostsPage({int page = 1});
  Future<AppResult<void>> deletePost(String id);

  /// Triggers real, immediate delivery via the backend's queue
  /// (`PublishPostJob` -> the provider's real API) for the given pages, or
  /// the post's own stored targets if [socialPageIds] is omitted.
  Future<AppResult<void>> publishNow(
    String postId, {
    List<String> socialPageIds = const <String>[],
  });
}
