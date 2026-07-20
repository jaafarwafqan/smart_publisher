import 'metrics_registry.dart';

class PerformanceMonitor {
  const PerformanceMonitor({this.metrics});

  final MetricsRegistry? metrics;

  Future<T> measureAsync<T>(String name, Future<T> Function() action) async {
    final watch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      watch.stop();
      (metrics ?? globalMetricsRegistry).recordDuration(name, watch.elapsed);
    }
  }

  T measureSync<T>(String name, T Function() action) {
    final watch = Stopwatch()..start();
    try {
      return action();
    } finally {
      watch.stop();
      (metrics ?? globalMetricsRegistry).recordDuration(name, watch.elapsed);
    }
  }
}
