import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

class SchedulePost extends BaseUseCase<PostEntity, PostEntity> {
  const SchedulePost({required this.repository});

  final PostRepository repository;

  @override
  Future<AppResult<PostEntity>> call(PostEntity params) {
    return repository.updatePost(
      PostEntity(
        id: params.id,
        title: params.title,
        body: params.body,
        status: 'scheduled',
        createdAt: params.createdAt,
        updatedAt: DateTime.now(),
        aiImproved: params.aiImproved,
        hasMedia: params.hasMedia,
        scheduledAt: params.scheduledAt,
        attachments: params.attachments,
        platforms: params.platforms,
      ),
    );
  }
}
