import '../release/release_config.dart';

final class FeatureFlagKeys {
  FeatureFlagKeys._();

  static const String performanceDashboard = 'performance_dashboard';
  static const String laravelQueueSync = 'laravel_queue_sync';
  static const String canaryPublishPipeline = 'canary_publish_pipeline';
}

class FeatureFlags {
  FeatureFlags({ReleaseConfig? releaseConfig, Map<String, bool>? overrides})
    : releaseConfig = releaseConfig ?? ReleaseConfig.fromEnvironment(),
      _overrides = overrides ?? const <String, bool>{};

  final ReleaseConfig releaseConfig;
  final Map<String, bool> _overrides;

  bool isEnabled(String key, {String? rolloutKey}) {
    final configured = _overrides[key] ?? _defaults[key] ?? false;
    if (!configured) {
      return false;
    }

    if (key == FeatureFlagKeys.canaryPublishPipeline) {
      if (rolloutKey == null || rolloutKey.isEmpty) {
        return false;
      }
      return releaseConfig.isUserInCanary(rolloutKey);
    }

    return true;
  }

  static final Map<String, bool> _defaults = <String, bool>{
    FeatureFlagKeys.performanceDashboard: _envBool(
      'SP_FF_PERFORMANCE_DASHBOARD',
      true,
    ),
    FeatureFlagKeys.laravelQueueSync: _envBool(
      'SP_FF_LARAVEL_QUEUE_SYNC',
      true,
    ),
    FeatureFlagKeys.canaryPublishPipeline: _envBool(
      'SP_FF_CANARY_PUBLISH_PIPELINE',
      false,
    ),
  };

  static bool _envBool(String key, bool fallback) {
    final raw = String.fromEnvironment(key, defaultValue: '').toLowerCase();
    if (raw.isEmpty) {
      return fallback;
    }
    return raw == '1' || raw == 'true' || raw == 'yes' || raw == 'on';
  }
}

final FeatureFlags globalFeatureFlags = FeatureFlags();
