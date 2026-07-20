import 'metrics_registry.dart';

enum AlertSeverity { warning, critical }

class AlertSignal {
  const AlertSignal({
    required this.key,
    required this.severity,
    required this.message,
  });

  final String key;
  final AlertSeverity severity;
  final String message;
}

class MonitoringAlertPolicy {
  const MonitoringAlertPolicy({
    this.crashRateThreshold = 0.02,
    this.publishFailureRateThreshold = 0.05,
    this.apiLatencyThresholdMs = 1200,
    this.queueLengthThreshold = 200,
    this.retryStormThreshold = 50,
  });

  final double crashRateThreshold;
  final double publishFailureRateThreshold;
  final double apiLatencyThresholdMs;
  final int queueLengthThreshold;
  final int retryStormThreshold;

  List<AlertSignal> evaluate(MetricsRegistry metrics) {
    final alerts = <AlertSignal>[];

    final crashRate = metrics.gauge('ops.crash_rate').toDouble();
    if (crashRate >= crashRateThreshold) {
      alerts.add(
        AlertSignal(
          key: 'crash_rate',
          severity: AlertSeverity.critical,
          message:
              'Crash rate $crashRate exceeded threshold $crashRateThreshold',
        ),
      );
    }

    final publishFailureRate = metrics
        .gauge('ops.publish_failure_rate')
        .toDouble();
    if (publishFailureRate >= publishFailureRateThreshold) {
      alerts.add(
        AlertSignal(
          key: 'publish_failure_rate',
          severity: AlertSeverity.critical,
          message:
              'Publish failure rate $publishFailureRate exceeded threshold $publishFailureRateThreshold',
        ),
      );
    }

    final apiLatencyMs = metrics.averageDurationMs('http.request.duration');
    if (apiLatencyMs >= apiLatencyThresholdMs) {
      alerts.add(
        AlertSignal(
          key: 'api_latency',
          severity: AlertSeverity.warning,
          message:
              'Average API latency ${apiLatencyMs.toStringAsFixed(1)}ms exceeded threshold ${apiLatencyThresholdMs.toStringAsFixed(1)}ms',
        ),
      );
    }

    final queueLength = metrics.gauge('ops.queue.length').toInt();
    if (queueLength >= queueLengthThreshold) {
      alerts.add(
        AlertSignal(
          key: 'queue_length',
          severity: AlertSeverity.warning,
          message:
              'Queue length $queueLength exceeded threshold $queueLengthThreshold',
        ),
      );
    }

    final retryStormCount = metrics.counter('ops.retry_storm.count');
    if (retryStormCount >= retryStormThreshold) {
      alerts.add(
        AlertSignal(
          key: 'retry_storm',
          severity: AlertSeverity.critical,
          message:
              'Retry storm count $retryStormCount exceeded threshold $retryStormThreshold',
        ),
      );
    }

    return alerts;
  }
}
