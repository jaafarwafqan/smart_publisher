import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../../../posts/domain/entities/post_entity.dart';

abstract class ScheduleRepository extends BaseRepository<PostEntity> {
  const ScheduleRepository();

  Future<AppResult<PostEntity>> schedulePost(PostEntity post);
  Future<AppResult<void>> cancelSchedule(String postId);
}
