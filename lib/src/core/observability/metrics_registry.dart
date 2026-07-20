class MetricsRegistry {
  MetricsRegistry()
    : _counters = <String, int>{},
      _timersMs = <String, List<int>>{},
      _gauges = <String, num>{};

  final Map<String, int> _counters;
  final Map<String, List<int>> _timersMs;
  final Map<String, num> _gauges;

  void increment(String metric, {int by = 1}) {
    _counters[metric] = (_counters[metric] ?? 0) + by;
  }

  void recordDuration(String metric, Duration value) {
    final list = _timersMs.putIfAbsent(metric, () => <int>[]);
    list.add(value.inMilliseconds);
  }

  int counter(String metric) => _counters[metric] ?? 0;

  void setGauge(String metric, num value) {
    _gauges[metric] = value;
  }

  num gauge(String metric) => _gauges[metric] ?? 0;

  double averageDurationMs(String metric) {
    final values = _timersMs[metric];
    if (values == null || values.isEmpty) {
      return 0;
    }
    final total = values.fold<int>(0, (sum, item) => sum + item);
    return total / values.length;
  }
}

final MetricsRegistry globalMetricsRegistry = MetricsRegistry();
