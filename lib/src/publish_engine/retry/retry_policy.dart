class RetryPolicy {
  const RetryPolicy({this.maxAttempts = 3, this.backoffSeconds = 5});

  final int maxAttempts;
  final int backoffSeconds;

  Future<T> execute<T>({
    required Future<T> Function() operation,
    required Duration Function(int attempt) backoff,
    bool Function(Object error)? shouldRetry,
  }) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        final retryAllowed = shouldRetry == null || shouldRetry(error);
        if (attempt == maxAttempts || !retryAllowed) {
          rethrow;
        }
        await Future<void>.delayed(backoff(attempt));
      }
    }

    throw StateError('Retry policy reached an unreachable state.');
  }
}
