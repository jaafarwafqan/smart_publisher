class PublishDeliveryFailure {
  const PublishDeliveryFailure({
    required this.platformId,
    required this.retryable,
    required this.code,
    required this.message,
  });

  final String platformId;
  final bool retryable;
  final String code;
  final String message;
}

class PublishStepFailure implements Exception {
  const PublishStepFailure(this.failures);

  final List<PublishDeliveryFailure> failures;

  bool get hasRetryable => failures.any((failure) => failure.retryable);

  PublishDeliveryFailure get first => failures.first;

  @override
  String toString() {
    return 'PublishStepFailure(${failures.length} failures)';
  }
}
