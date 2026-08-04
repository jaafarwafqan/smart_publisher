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
      // This app has no audited progressive-delivery controller. Keep the
      // legacy key fail-closed instead of pretending a local hash controls a
      // production rollout.
      return false;
    }

    return true;
  }

  // String.fromEnvironment must be invoked directly with a literal key at each
  // call site (the compiler substitutes it at compile time) — it cannot be
  // routed through a helper taking a runtime `key` parameter, which is what
  // the previous _envBool(key, fallback) did and crashed with
  // "Unsupported operation: String.fromEnvironment can only be used as a
  // const constructor" the moment any flag was actually read at runtime.
  static final Map<String, bool> _defaults = <String, bool>{
    FeatureFlagKeys.performanceDashboard: _parseBool(
      const String.fromEnvironment('SP_FF_PERFORMANCE_DASHBOARD'),
      true,
    ),
    FeatureFlagKeys.laravelQueueSync: _parseBool(
      const String.fromEnvironment('SP_FF_LARAVEL_QUEUE_SYNC'),
      true,
    ),
    FeatureFlagKeys.canaryPublishPipeline: false,
  };

  static bool _parseBool(String raw, bool fallback) {
    final value = raw.toLowerCase();
    if (value.isEmpty) {
      return fallback;
    }
    return value == '1' || value == 'true' || value == 'yes' || value == 'on';
  }
}

final FeatureFlags globalFeatureFlags = FeatureFlags();
