import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../../../schedule/domain/repositories/schedule_repository.dart';
import '../entities/post_entity.dart';

class SchedulePost extends BaseUseCase<PostEntity, PostEntity> {
  const SchedulePost({required this.repository});

  final ScheduleRepository repository;

  @override
  Future<AppResult<PostEntity>> call(PostEntity params) {
    if (params.scheduledAt == null) {
      return Future<AppResult<PostEntity>>.value(
        Failure<PostEntity>('A schedule date/time is required.'),
      );
    }

    return repository.schedulePost(params);
  }
}
