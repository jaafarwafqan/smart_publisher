import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/publish_job_entity.dart';

abstract class PublishRepository extends BaseRepository<PublishJobEntity> {
  const PublishRepository();

  Future<AppResult<PublishJobEntity>> createPublishJob(PublishJobEntity job);
  Future<AppResult<PublishJobEntity>> updatePublishJob(PublishJobEntity job);
  Future<AppResult<List<PublishJobEntity>>> getJobs();
  Future<AppResult<void>> deleteJob(String id);
}
