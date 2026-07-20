import '../../platforms/core/platform_factory.dart';
import '../engine/publish_context.dart';
import '../engine/publish_step.dart';
import '../reliability/backoff_policy.dart';
import '../reliability/circuit_breaker_policy.dart';
import '../reliability/idempotency_policy.dart';
import '../reliability/publish_error_classifier.dart';
import '../reliability/publish_step_failure.dart';
import '../reliability/rate_limit_policy.dart';
import '../reliability/timeout_policy.dart';
import '../retry/retry_policy.dart';

class PublishStepImpl implements PublishStep {
  PublishStepImpl({
    required this.platformFactory,
    RetryPolicy? retryPolicy,
    BackoffPolicy? backoffPolicy,
    TimeoutPolicy? timeoutPolicy,
    CircuitBreakerPolicy? circuitBreakerPolicy,
    RateLimitPolicy? rateLimitPolicy,
    IdempotencyPolicy? idempotencyPolicy,
    PublishErrorClassifier? errorClassifier,
  }) : retryPolicy = retryPolicy ?? const RetryPolicy(),
       backoffPolicy = backoffPolicy ?? const BackoffPolicy(),
       timeoutPolicy = timeoutPolicy ?? const TimeoutPolicy(),
       circuitBreakerPolicy = circuitBreakerPolicy ?? CircuitBreakerPolicy(),
       rateLimitPolicy = rateLimitPolicy ?? RateLimitPolicy(),
       idempotencyPolicy = idempotencyPolicy ?? IdempotencyPolicy(),
       errorClassifier = errorClassifier ?? const PublishErrorClassifier();

  final PlatformFactory platformFactory;
  final RetryPolicy retryPolicy;
  final BackoffPolicy backoffPolicy;
  final TimeoutPolicy timeoutPolicy;
  final CircuitBreakerPolicy circuitBreakerPolicy;
  final RateLimitPolicy rateLimitPolicy;
  final IdempotencyPolicy idempotencyPolicy;
  final PublishErrorClassifier errorClassifier;

  @override
  Future<void> execute(PublishContext context) async {
    final failures = <PublishDeliveryFailure>[];

    for (final target in context.targets) {
      final resolvedPublishers = platformFactory.createForTarget(target);
      for (final resolved in resolvedPublishers) {
        final key =
            '${context.post.id}:${target.destinationKey}:${resolved.platformId}';

        if (!idempotencyPolicy.acquire(key)) {
          continue;
        }

        try {
          await rateLimitPolicy.acquire(resolved.platformId);
          await circuitBreakerPolicy.execute(resolved.platformId, () {
            return retryPolicy.execute(
              operation: () {
                return timeoutPolicy.run(() async {
                  final result = await resolved.publisher.publish(context.post);
                  if (!result.success) {
                    throw StateError(
                      'Publishing failed for ${resolved.platformId}: ${result.message}',
                    );
                  }
                });
              },
              backoff: (attempt) => backoffPolicy.delayForAttempt(attempt),
              shouldRetry: (error) => errorClassifier.classify(error).retryable,
            );
          });
          idempotencyPolicy.complete(key);
        } catch (error) {
          idempotencyPolicy.release(key);
          final classification = errorClassifier.classify(error);
          failures.add(
            PublishDeliveryFailure(
              platformId: resolved.platformId,
              retryable: classification.retryable,
              code: classification.code,
              message: classification.message,
            ),
          );
        }
      }
    }

    if (failures.isNotEmpty) {
      throw PublishStepFailure(failures);
    }
  }
}
