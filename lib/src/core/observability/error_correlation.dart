String correlateError(Object error, [StackTrace? stackTrace]) {
  final source = '${error.runtimeType}:${error.toString()}:${stackTrace ?? ''}';
  final hash = source.hashCode.toUnsigned(32).toRadixString(16);
  return 'err-$hash';
}
