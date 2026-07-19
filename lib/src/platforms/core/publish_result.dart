class PublishResult {
  const PublishResult({
    required this.success,
    required this.message,
    this.externalId,
    this.errorCode,
  });

  final bool success;
  final String message;
  final String? externalId;
  final String? errorCode;
}
