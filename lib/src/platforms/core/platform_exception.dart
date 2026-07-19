class PlatformException implements Exception {
  const PlatformException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'PlatformException(message: $message, code: $code)';
}
