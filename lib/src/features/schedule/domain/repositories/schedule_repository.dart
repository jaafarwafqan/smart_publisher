import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../../../posts/domain/entities/post_entity.dart';
import '../entities/schedule_entity.dart';

abstract class ScheduleRepository extends BaseRepository<PostEntity> {
  const ScheduleRepository();

  /// Real, dedicated call to `POST /posts/{id}/schedule` — never routed
  /// through the generic post-update endpoint, whose request DTO doesn't
  /// carry `status`/`scheduled_at` at all.
  Future<AppResult<PostEntity>> schedulePost(PostEntity post);

  Future<AppResult<void>> cancelSchedule(String postId);

  Future<AppResult<List<ScheduleEntity>>> getCalendarEntries();
}
