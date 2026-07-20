abstract interface class CrashReporter {
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    String? traceId,
    String? correlationId,
    Map<String, Object?> context,
  });
}

class ConsoleCrashReporter implements CrashReporter {
  const ConsoleCrashReporter();

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    String? traceId,
    String? correlationId,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    // ignore: avoid_print
    print(
      '[CRASH] trace=$traceId correlation=$correlationId error=$error context=$context stack=$stackTrace',
    );
  }
}
