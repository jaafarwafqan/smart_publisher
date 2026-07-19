class RetryPolicy {
  const RetryPolicy({this.maxAttempts = 3, this.backoffSeconds = 5});

  final int maxAttempts;
  final int backoffSeconds;
}
