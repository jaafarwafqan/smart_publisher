import 'package:sentry_flutter/sentry_flutter.dart';

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

/// Production reporter selected only after Sentry has initialized with a
/// non-empty build-time DSN. The console reporter remains useful locally and
/// keeps development/test builds from sending events to a real project.
class SentryCrashReporter implements CrashReporter {
  const SentryCrashReporter();

  @override
  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    String? traceId,
    String? correlationId,
    Map<String, Object?> context = const <String, Object?>{},
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (traceId != null) {
          scope.setTag('trace_id', traceId);
        }
        if (correlationId != null) {
          scope.setTag('correlation_id', correlationId);
        }
        if (context.isNotEmpty) {
          scope.setContexts('smart_publisher', context);
        }
      },
    );
  }
}
