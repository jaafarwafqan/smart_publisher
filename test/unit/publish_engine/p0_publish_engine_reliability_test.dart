import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/domain/publish_target.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/platforms/core/auth_result.dart';
import 'package:smart_publisher/src/platforms/core/platform_capability.dart';
import 'package:smart_publisher/src/platforms/core/platform_factory.dart';
import 'package:smart_publisher/src/platforms/core/publish_result.dart';
import 'package:smart_publisher/src/platforms/core/social_platform.dart';
import 'package:smart_publisher/src/publish_engine/engine/publish_engine.dart';
import 'package:smart_publisher/src/publish_engine/reliability/backoff_policy.dart';
import 'package:smart_publisher/src/publish_engine/reliability/circuit_breaker_policy.dart';
import 'package:smart_publisher/src/publish_engine/reliability/timeout_policy.dart';
import 'package:smart_publisher/src/publish_engine/retry/retry_policy.dart';

void main() {
  group('P0 - Publish Engine Reliability', () {
    const post = PostEntity(id: 'p0-post', title: 'Title', body: 'Body');
    const target = PublishTarget(
      category: PublishTargetCategory.social,
      destinationKey: 'test-social',
    );

    test(
      'concurrent publish does not double publish and queue remains consistent',
      () async {
        final platform = _ScriptedSocialPlatform(
          publishDelay: const Duration(milliseconds: 40),
        );
        final engine = PublishEngine(
          platformFactory: PlatformFactory(plugins: <SocialPlatform>[platform]),
        );

        await Future.wait<void>(<Future<void>>[
          engine.publish(post: post, targets: const <PublishTarget>[target]),
          engine.publish(post: post, targets: const <PublishTarget>[target]),
        ]);

        final job = await engine.queueManager.findById(post.id);
        expect(job, isNotNull);
        expect(job?.status.name, 'succeeded');
        expect(engine.queueManager.readyForRecovery(), isEmpty);
        expect(platform.publishAttempts, 1);
        expect(platform.successfulPublishes, 1);
      },
    );

    test('duplicate publish command does not execute twice', () async {
      final platform = _ScriptedSocialPlatform();
      final engine = PublishEngine(
        platformFactory: PlatformFactory(plugins: <SocialPlatform>[platform]),
      );

      await engine.publish(post: post, targets: const <PublishTarget>[target]);
      await engine.publish(post: post, targets: const <PublishTarget>[target]);

      expect(platform.publishAttempts, 1);
      expect(platform.successfulPublishes, 1);
    });

    test(
      'retry exhaustion performs exact attempts and returns failure',
      () async {
        final platform = _ScriptedSocialPlatform(
          failureScript: <Object>[
            StateError('503 temporary'),
            StateError('503 temporary'),
            StateError('503 temporary'),
          ],
        );
        final engine = PublishEngine(
          platformFactory: PlatformFactory(plugins: <SocialPlatform>[platform]),
          retryPolicy: const RetryPolicy(maxAttempts: 3),
          backoffPolicy: const BackoffPolicy(baseDelayMs: 1, maxDelayMs: 2),
        );

        await expectLater(
          () => engine.publish(
            post: post,
            targets: const <PublishTarget>[target],
          ),
          throwsA(isA<Exception>()),
        );

        final job = await engine.queueManager.findById(post.id);
        expect(platform.publishAttempts, 3);
        expect(job?.status.name, 'failed');
        expect(job?.retryCount, 1);
      },
    );

    test('timeout is enforced and execution returns promptly', () async {
      final platform = _ScriptedSocialPlatform(
        publishDelay: const Duration(milliseconds: 250),
      );
      final engine = PublishEngine(
        platformFactory: PlatformFactory(plugins: <SocialPlatform>[platform]),
        retryPolicy: const RetryPolicy(maxAttempts: 1),
        timeoutPolicy: const TimeoutPolicy(timeout: Duration(milliseconds: 30)),
      );

      final watch = Stopwatch()..start();
      await expectLater(
        () =>
            engine.publish(post: post, targets: const <PublishTarget>[target]),
        throwsA(isA<Exception>()),
      );
      watch.stop();

      expect(watch.elapsedMilliseconds, lessThan(180));
      await Future<void>.delayed(const Duration(milliseconds: 270));
      expect(platform.inFlightPublishes, 0);
    });

    test('circuit breaker transitions closed-open-half-open-closed', () async {
      final breaker = CircuitBreakerPolicy(
        failureThreshold: 2,
        resetAfter: const Duration(milliseconds: 80),
      );
      var calls = 0;

      Future<void> failAction() async {
        calls += 1;
        throw StateError('503 transient');
      }

      await expectLater(
        () => breaker.execute('fb', failAction),
        throwsStateError,
      );
      await expectLater(
        () => breaker.execute('fb', failAction),
        throwsStateError,
      );
      await expectLater(
        () => breaker.execute('fb', () async => null),
        throwsStateError,
      );

      await Future<void>.delayed(const Duration(milliseconds: 90));

      await breaker.execute<void>('fb', () async {
        calls += 1;
      });

      await breaker.execute<void>('fb', () async {
        calls += 1;
      });

      expect(calls, 4);
    });
  });
}

class _ScriptedSocialPlatform implements SocialPlatform {
  _ScriptedSocialPlatform({
    this.publishDelay = Duration.zero,
    List<Object> failureScript = const <Object>[],
  }) : _failureScript = List<Object>.from(failureScript);

  final Duration publishDelay;
  final List<Object> _failureScript;

  int publishAttempts = 0;
  int successfulPublishes = 0;
  int inFlightPublishes = 0;

  @override
  String get platformId => 'test-platform';

  @override
  Set<String> get supportedTargetKeys => const <String>{'test-social'};

  @override
  Future<AuthResult> connect() async {
    return const AuthResult(success: true, message: 'ok');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<PublishResult> publish(PostEntity post) async {
    publishAttempts += 1;
    inFlightPublishes += 1;
    try {
      if (publishDelay > Duration.zero) {
        await Future<void>.delayed(publishDelay);
      }
      if (_failureScript.isNotEmpty) {
        final next = _failureScript.removeAt(0);
        throw next;
      }
      successfulPublishes += 1;
      return const PublishResult(success: true, message: 'published');
    } finally {
      inFlightPublishes -= 1;
    }
  }

  @override
  bool supportsTarget(PublishTarget target) {
    return target.destinationKey == 'test-social';
  }

  @override
  Future<bool> validate() async => true;

  @override
  PlatformCapability capability() => const PlatformCapability();
}
