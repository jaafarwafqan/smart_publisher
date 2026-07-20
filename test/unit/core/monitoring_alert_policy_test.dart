import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/observability/alert_policy.dart';
import 'package:smart_publisher/src/core/observability/metrics_registry.dart';

void main() {
  group('MonitoringAlertPolicy', () {
    test('raises all configured alerts when thresholds are exceeded', () {
      final metrics = MetricsRegistry();
      final policy = MonitoringAlertPolicy(
        crashRateThreshold: 0.01,
        publishFailureRateThreshold: 0.04,
        apiLatencyThresholdMs: 500,
        queueLengthThreshold: 10,
        retryStormThreshold: 3,
      );

      metrics.setGauge('ops.crash_rate', 0.03);
      metrics.setGauge('ops.publish_failure_rate', 0.09);
      metrics.recordDuration(
        'http.request.duration',
        const Duration(milliseconds: 900),
      );
      metrics.setGauge('ops.queue.length', 30);
      metrics.increment('ops.retry_storm.count', by: 5);

      final alerts = policy.evaluate(metrics);
      expect(alerts.length, 5);
      expect(
        alerts.map((a) => a.key),
        containsAll(<String>[
          'crash_rate',
          'publish_failure_rate',
          'api_latency',
          'queue_length',
          'retry_storm',
        ]),
      );
    });

    test('returns no alerts when metrics are healthy', () {
      final metrics = MetricsRegistry();
      final policy = MonitoringAlertPolicy();

      metrics.setGauge('ops.crash_rate', 0.001);
      metrics.setGauge('ops.publish_failure_rate', 0.01);
      metrics.recordDuration(
        'http.request.duration',
        const Duration(milliseconds: 120),
      );
      metrics.setGauge('ops.queue.length', 5);
      metrics.increment('ops.retry_storm.count', by: 1);

      final alerts = policy.evaluate(metrics);
      expect(alerts, isEmpty);
    });
  });
}
