import '../../features/posts/domain/entities/post_entity.dart';
import '../../platforms/core/platform_factory.dart';
import '../../platforms/core/platform_type.dart';
import '../engine/publish_context.dart';
import '../engine/publish_pipeline.dart';
import '../engine/publish_validator.dart';
import '../engine/publish_executor.dart';
import '../engine/publish_result_builder.dart';
import '../jobs/publish_job.dart';
import '../queue/queue_manager.dart';
import '../retry/retry_policy.dart';
import '../logs/publish_logger.dart';

class PublishEngine {
  PublishEngine({
    PlatformFactory? platformFactory,
    QueueManager? queueManager,
    RetryPolicy? retryPolicy,
    PublishLogger? logger,
  }) : platformFactory = platformFactory ?? const PlatformFactory(),
       queueManager = queueManager ?? const QueueManager(),
       retryPolicy = retryPolicy ?? const RetryPolicy(),
       logger = logger ?? const PublishLogger(),
       resultBuilder = const PublishResultBuilder();

  final PlatformFactory platformFactory;
  final QueueManager queueManager;
  final RetryPolicy retryPolicy;
  final PublishLogger logger;
  final PublishResultBuilder resultBuilder;

  Future<void> publish({
    required PostEntity post,
    required List<PlatformType> platforms,
  }) async {
    final context = PublishContext(post: post, platforms: platforms);
    final pipeline = PublishPipeline([
      ValidateStep(),
      PublishStepImpl(platformFactory: platformFactory),
    ]);

    await pipeline.run(context);

    final job = PublishJob(
      id: post.id,
      postId: post.id,
      platforms: platforms,
      status: 'queued',
      retryCount: 0,
    );

    await queueManager.enqueue(job.id);
    logger.log('Publish job queued for ${post.id}');
  }
}
