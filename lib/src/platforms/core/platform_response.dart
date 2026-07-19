class PlatformResponse<T> {
  const PlatformResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
  });

  final bool success;
  final String message;
  final T? data;
  final String? errorCode;
}
