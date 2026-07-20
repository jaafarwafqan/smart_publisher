class BackoffPolicy {
  const BackoffPolicy({this.baseDelayMs = 500, this.maxDelayMs = 5000});

  final int baseDelayMs;
  final int maxDelayMs;

  Duration delayForAttempt(int attempt) {
    final multiplier = 1 << (attempt - 1);
    final delay = baseDelayMs * multiplier;
    final bounded = delay > maxDelayMs ? maxDelayMs : delay;
    return Duration(milliseconds: bounded);
  }
}
