import '../../features/posts/domain/entities/post_entity.dart';
import '../../core/events/event_dispatcher.dart';
import '../../core/observability/metrics_registry.dart';
import '../../domain/publish_target.dart';
import '../../platforms/core/platform_factory.dart';
import '../../features/analytics/events/analytics_updated_event.dart';
import '../../features/publish/events/publish_failed_event.dart';
import '../../features/publish/events/publish_started_event.dart';
import '../../features/publish/events/publish_succeeded_event.dart';
import '../engine/publish_context.dart';
import '../engine/publish_pipeline.dart';
import '../engine/publish_validator.dart';
import '../engine/publish_executor.dart';
import '../engine/publish_result_builder.dart';
import '../jobs/publish_job.dart';
import '../queue/queue_manager.dart';
import '../reliability/backoff_policy.dart';
import '../reliability/circuit_breaker_policy.dart';
import '../reliability/idempotency_policy.dart';
import '../reliability/publish_error_classifier.dart';
import '../reliability/publish_recovery.dart';
import '../reliability/publish_step_failure.dart';
import '../reliability/rate_limit_policy.dart';
import '../reliability/timeout_policy.dart';
import '../retry/retry_policy.dart';
import '../logs/publish_logger.dart';

class PublishEngine {
  PublishEngine({
    PlatformFactory? platformFactory,
    QueueManager? queueManager,
    RetryPolicy? retryPolicy,
    BackoffPolicy? backoffPolicy,
    TimeoutPolicy? timeoutPolicy,
    CircuitBreakerPolicy? circuitBreakerPolicy,
    RateLimitPolicy? rateLimitPolicy,
    IdempotencyPolicy? idempotencyPolicy,
    PublishErrorClassifier? errorClassifier,
    PublishRecovery? recovery,
    PublishLogger? logger,
    EventDispatcher? eventDispatcher,
  }) : this._internal(
         platformFactory: platformFactory ?? PlatformFactory(),
         queueManager: queueManager ?? QueueManager(),
         retryPolicy: retryPolicy ?? const RetryPolicy(),
         backoffPolicy: backoffPolicy ?? const BackoffPolicy(),
         timeoutPolicy: timeoutPolicy ?? const TimeoutPolicy(),
         circuitBreakerPolicy: circuitBreakerPolicy ?? CircuitBreakerPolicy(),
         rateLimitPolicy: rateLimitPolicy ?? RateLimitPolicy(),
         idempotencyPolicy: idempotencyPolicy ?? IdempotencyPolicy(),
         errorClassifier: errorClassifier ?? const PublishErrorClassifier(),
         recovery: recovery,
         logger: logger ?? const PublishLogger(),
         eventDispatcher: eventDispatcher,
       );

  PublishEngine._internal({
    required this.platformFactory,
    required this.queueManager,
    required this.retryPolicy,
    required this.backoffPolicy,
    required this.timeoutPolicy,
    required this.circuitBreakerPolicy,
    required this.rateLimitPolicy,
    required this.idempotencyPolicy,
    required this.errorClassifier,
    PublishRecovery? recovery,
    required this.logger,
    this.eventDispatcher,
  }) : recovery =
           recovery ??
           PublishRecovery(
             queueManager: queueManager,
             backoffPolicy: backoffPolicy,
             retryPolicy: retryPolicy,
           ),
       resultBuilder = const PublishResultBuilder();

  final PlatformFactory platformFactory;
  final QueueManager queueManager;
  final RetryPolicy retryPolicy;
  final BackoffPolicy backoffPolicy;
  final TimeoutPolicy timeoutPolicy;
  final CircuitBreakerPolicy circuitBreakerPolicy;
  final RateLimitPolicy rateLimitPolicy;
  final IdempotencyPolicy idempotencyPolicy;
  final PublishErrorClassifier errorClassifier;
  final PublishRecovery recovery;
  final PublishLogger logger;
  final EventDispatcher? eventDispatcher;
  final PublishResultBuilder resultBuilder;

  Future<void> publish({
    required PostEntity post,
    required List<PublishTarget> targets,
  }) async {
    await recoverPendingPublishes();

    final job = PublishJob(
      id: post.id,
      postId: post.id,
      post: post,
      targets: targets,
      status: PublishJobStatus.pending,
      retryCount: 0,
    );

    await queueManager.enqueue(job);
    await _runJob(job);
  }

  Future<void> recoverPendingPublishes() async {
    final jobs = queueManager.readyForRecovery();
    for (final job in jobs) {
      await _runJob(job);
    }
  }

  Future<void> _runJob(PublishJob job) async {
    final timer = Stopwatch()..start();
    await queueManager.markProcessing(job.id);
    await eventDispatcher?.dispatch(
      PublishStartedEvent(jobId: job.id, postId: job.postId),
    );

    final context = PublishContext(post: job.post, targets: job.targets);
    final pipeline = PublishPipeline([
      ValidateStep(),
      PublishStepImpl(
        platformFactory: platformFactory,
        retryPolicy: retryPolicy,
        backoffPolicy: backoffPolicy,
        timeoutPolicy: timeoutPolicy,
        circuitBreakerPolicy: circuitBreakerPolicy,
        rateLimitPolicy: rateLimitPolicy,
        idempotencyPolicy: idempotencyPolicy,
        errorClassifier: errorClassifier,
      ),
    ]);

    try {
      await pipeline.run(context);
      await queueManager.markSucceeded(job.id);
      timer.stop();
      globalMetricsRegistry.increment('publish.jobs.succeeded');
      globalMetricsRegistry.recordDuration('publish.latency', timer.elapsed);
      await eventDispatcher?.dispatch(
        PublishSucceededEvent(jobId: job.id, postId: job.postId),
      );
      await eventDispatcher?.dispatch(
        AnalyticsUpdatedEvent(postId: job.postId),
      );
      logger.log('Publish job succeeded for ${job.postId}');
    } on PublishStepFailure catch (error) {
      timer.stop();
      globalMetricsRegistry.increment('publish.jobs.failed');
      globalMetricsRegistry.recordDuration('publish.latency', timer.elapsed);
      final first = error.first;
      final hasRetryable = error.hasRetryable;
      if (hasRetryable) {
        await recovery.scheduleRetry(
          job: job,
          errorCode: first.code,
          errorMessage: first.message,
        );
      } else {
        await queueManager.markFailed(
          job.id,
          errorCode: first.code,
          errorMessage: first.message,
        );
      }
      await eventDispatcher?.dispatch(
        PublishFailedEvent(
          jobId: job.id,
          postId: job.postId,
          errorCode: first.code,
          errorMessage: first.message,
        ),
      );
      rethrow;
    } catch (error) {
      timer.stop();
      globalMetricsRegistry.increment('publish.jobs.failed');
      globalMetricsRegistry.recordDuration('publish.latency', timer.elapsed);
      final classification = errorClassifier.classify(error);
      if (classification.retryable) {
        await recovery.scheduleRetry(
          job: job,
          errorCode: classification.code,
          errorMessage: classification.message,
        );
      } else {
        await queueManager.markFailed(
          job.id,
          errorCode: classification.code,
          errorMessage: classification.message,
        );
      }
      await eventDispatcher?.dispatch(
        PublishFailedEvent(
          jobId: job.id,
          postId: job.postId,
          errorCode: classification.code,
          errorMessage: classification.message,
        ),
      );
      rethrow;
    }
  }
}
