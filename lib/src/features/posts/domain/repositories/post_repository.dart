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

  /// Sprint F (role/permission remediation): the manager/admin/owner
  /// Approvals queue — GET /posts?approval_status=pending, not a separate
  /// endpoint. Requires a connection; there is no offline/local mode for
  /// reviewing someone else's pending request.
  Future<AppResult<PaginatedResult<PostEntity>>> getPendingApprovalsPage({
    int page = 1,
  });

  /// POST /posts/{id}/approve — runs whatever action (schedule/publish-now)
  /// was originally requested, using the data captured at request time.
  Future<AppResult<PostEntity>> approvePost(String postId);

  /// POST /posts/{id}/reject — [note] is optional context for the requester.
  Future<AppResult<PostEntity>> rejectPost(String postId, {String? note});
}
