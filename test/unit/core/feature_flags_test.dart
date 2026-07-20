import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/feature_flags/feature_flags.dart';
import 'package:smart_publisher/src/core/release/release_config.dart';

void main() {
  group('FeatureFlags', () {
    test('returns false for unknown flag', () {
      final flags = FeatureFlags(overrides: const <String, bool>{});

      expect(flags.isEnabled('unknown_flag'), isFalse);
    });

    test('uses override values for standard flags', () {
      final flags = FeatureFlags(
        overrides: const <String, bool>{
          FeatureFlagKeys.performanceDashboard: false,
          FeatureFlagKeys.laravelQueueSync: true,
        },
      );

      expect(flags.isEnabled(FeatureFlagKeys.performanceDashboard), isFalse);
      expect(flags.isEnabled(FeatureFlagKeys.laravelQueueSync), isTrue);
    });

    test('canary flag requires rollout key and matching canary bucket', () {
      final flags = FeatureFlags(
        releaseConfig: ReleaseConfig(
          channel: ReleaseChannel.canary,
          canaryPercent: 100,
        ),
        overrides: const <String, bool>{
          FeatureFlagKeys.canaryPublishPipeline: true,
        },
      );

      expect(flags.isEnabled(FeatureFlagKeys.canaryPublishPipeline), isFalse);
      expect(
        flags.isEnabled(
          FeatureFlagKeys.canaryPublishPipeline,
          rolloutKey: 'user-123',
        ),
        isTrue,
      );
    });
  });
}
