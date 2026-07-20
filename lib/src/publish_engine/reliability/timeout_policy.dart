class TimeoutPolicy {
  const TimeoutPolicy({this.timeout = const Duration(seconds: 15)});

  final Duration timeout;

  Future<T> run<T>(Future<T> Function() action) {
    return action().timeout(timeout);
  }
}
