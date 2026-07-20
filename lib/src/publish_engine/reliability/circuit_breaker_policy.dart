class CircuitBreakerPolicy {
  CircuitBreakerPolicy({
    this.failureThreshold = 3,
    this.resetAfter = const Duration(minutes: 1),
  }) : _failureCount = <String, int>{},
       _openedAt = <String, DateTime>{};

  final int failureThreshold;
  final Duration resetAfter;
  final Map<String, int> _failureCount;
  final Map<String, DateTime> _openedAt;

  Future<T> execute<T>(String key, Future<T> Function() action) async {
    if (_isOpen(key)) {
      throw StateError('Circuit is open for $key');
    }

    try {
      final result = await action();
      _failureCount[key] = 0;
      _openedAt.remove(key);
      return result;
    } catch (_) {
      final current = (_failureCount[key] ?? 0) + 1;
      _failureCount[key] = current;
      if (current >= failureThreshold) {
        _openedAt[key] = DateTime.now();
      }
      rethrow;
    }
  }

  bool _isOpen(String key) {
    final openedAt = _openedAt[key];
    if (openedAt == null) {
      return false;
    }

    final elapsed = DateTime.now().difference(openedAt);
    if (elapsed >= resetAfter) {
      _openedAt.remove(key);
      _failureCount[key] = 0;
      return false;
    }
    return true;
  }
}
