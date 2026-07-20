import '../jobs/publish_job.dart';
import '../queue/queue_manager.dart';
import '../retry/retry_policy.dart';
import 'backoff_policy.dart';

class PublishRecovery {
  const PublishRecovery({
    required this.queueManager,
    required this.backoffPolicy,
    required this.retryPolicy,
  });

  final QueueManager queueManager;
  final BackoffPolicy backoffPolicy;
  final RetryPolicy retryPolicy;

  Future<void> scheduleRetry({
    required PublishJob job,
    required String errorCode,
    required String errorMessage,
  }) async {
    final nextAttempt = job.retryCount + 1;
    if (nextAttempt >= retryPolicy.maxAttempts) {
      await queueManager.markFailed(
        job.id,
        errorCode: errorCode,
        errorMessage: errorMessage,
        incrementRetryCount: true,
      );
      return;
    }

    final retryAt = DateTime.now().add(
      backoffPolicy.delayForAttempt(nextAttempt),
    );
    await queueManager.markFailed(
      job.id,
      errorCode: errorCode,
      errorMessage: errorMessage,
      incrementRetryCount: true,
      retryAt: retryAt,
    );
  }
}
