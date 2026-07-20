enum PlatformErrorType {
  validation,
  authentication,
  authorization,
  rateLimit,
  notFound,
  network,
  unavailable,
  unknown,
}

class PlatformErrorMapping {
  const PlatformErrorMapping({
    required this.type,
    required this.code,
    required this.message,
    this.retriable = false,
  });

  final PlatformErrorType type;
  final String code;
  final String message;
  final bool retriable;
}
