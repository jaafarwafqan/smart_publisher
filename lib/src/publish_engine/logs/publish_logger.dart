import '../../core/logger/app_logger.dart';
import '../../core/observability/performance_monitor.dart';

class PublishLogger {
  const PublishLogger({this.performanceMonitor = const PerformanceMonitor()});

  final PerformanceMonitor performanceMonitor;

  void log(String message) {
    performanceMonitor.measureSync(
      'publish.log.duration',
      () => AppLogger.structured(
        'INFO',
        'Publish log',
        context: <String, Object?>{'message': message},
      ),
    );
  }
}
