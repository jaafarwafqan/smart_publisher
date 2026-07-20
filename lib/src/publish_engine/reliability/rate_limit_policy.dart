class RateLimitPolicy {
  RateLimitPolicy({this.minInterval = const Duration(milliseconds: 300)})
    : _lastAttempt = <String, DateTime>{};

  final Duration minInterval;
  final Map<String, DateTime> _lastAttempt;

  Future<void> acquire(String key) async {
    final now = DateTime.now();
    final last = _lastAttempt[key];
    if (last != null) {
      final elapsed = now.difference(last);
      if (elapsed < minInterval) {
        await Future<void>.delayed(minInterval - elapsed);
      }
    }
    _lastAttempt[key] = DateTime.now();
  }
}
