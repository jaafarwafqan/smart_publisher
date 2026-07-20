import '../logger/app_logger.dart';
import '../observability/metrics_registry.dart';

class StartupProfiler {
  StartupProfiler._();

  static final StartupProfiler instance = StartupProfiler._();

  Stopwatch? _watch;

  void markStart() {
    _watch ??= Stopwatch()..start();
  }

  void markReady() {
    final watch = _watch;
    if (watch == null) {
      return;
    }

    if (watch.isRunning) {
      watch.stop();
    }

    globalMetricsRegistry.recordDuration('app.startup.time', watch.elapsed);
    AppLogger.structured(
      'INFO',
      'Startup ready',
      context: <String, Object?>{'startup_ms': watch.elapsedMilliseconds},
    );
  }
}
