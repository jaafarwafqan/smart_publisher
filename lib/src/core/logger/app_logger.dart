import 'dart:convert';
import 'dart:developer' as developer;

import '../observability/error_correlation.dart';
import '../observability/trace_context.dart';
import 'logger_service.dart';

class AppLogger implements LoggerService {
  const AppLogger();

  static const String _loggerName = 'SmartPublisher';

  // دوال Static للاستخدام خارج الـ Providers (مثل الـ Router)
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    const AppLogger().debug(message, error, stackTrace);
  }

  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    const AppLogger().info(message, error, stackTrace);
  }

  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    const AppLogger().warning(message, error, stackTrace);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    const AppLogger().error(message, error, stackTrace);
  }

  static void structured(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    const AppLogger()._emit(
      level: level,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _emit(
      level: 'DEBUG',
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _emit(
      level: 'INFO',
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _emit(
      level: 'WARN',
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _emit(
      level: 'ERROR',
      message: message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _emit({
    required String level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final traceId = TraceContext.currentTraceId() ?? TraceContext.newTraceId();
    final correlationId = error == null
        ? null
        : correlateError(error, stackTrace);

    final payload = <String, Object?>{
      'timestamp': DateTime.now().toIso8601String(),
      'level': level,
      'logger': _loggerName,
      'message': message,
      'trace_id': traceId,
      ...?correlationId == null
          ? null
          : <String, Object?>{'correlation_id': correlationId},
      if (context.isNotEmpty) 'context': context,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack': stackTrace.toString(),
    };

    final encoded = jsonEncode(payload);
    developer.log(
      encoded,
      name: _loggerName,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
