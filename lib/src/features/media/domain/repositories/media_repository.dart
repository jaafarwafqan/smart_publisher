import '../../../../core/base/base_repository.dart';
import '../../../../core/base/pagination.dart';
import '../../../../core/result/app_result.dart';
import '../../../posts/domain/entities/media_entity.dart';

abstract class MediaRepository extends BaseRepository<MediaEntity> {
  const MediaRepository();

  Future<AppResult<MediaEntity>> uploadMedia(MediaEntity media);
  Future<AppResult<MediaEntity>> compressMedia(MediaEntity media);
  Future<AppResult<void>> deleteMedia(String id);

  /// Real, server-side filtered/searched media list — replaces the previous
  /// client-side fabrication (scanning post attachment URLs). Unpaginated
  /// convenience for callers that want everything; [getMediaLibraryPage] is
  /// what the media library screen uses so accounts with more than one
  /// backend page of media aren't silently capped at the first page.
  Future<AppResult<List<MediaEntity>>> getMediaLibrary({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
  });

  Future<AppResult<PaginatedResult<MediaEntity>>> getMediaLibraryPage({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
    int page = 1,
  });

  /// Reuses an existing upload on another post (the backend endpoint has
  /// always existed; nothing in the app called it until now).
  Future<AppResult<void>> attachMediaToPost({
    required String mediaId,
    required String postId,
  });
}
