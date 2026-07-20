class MediaEngineException implements Exception {
  const MediaEngineException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'MediaEngineException(message: $message, code: $code)';
}
