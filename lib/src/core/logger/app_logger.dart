import 'dart:developer' as developer;
import 'logger_service.dart';

class AppLogger implements LoggerService {
  AppLogger._(); // Private constructor

  static final AppLogger instance = AppLogger._();

  // دوال Static للاستخدام خارج الـ Providers (مثل الـ Router)
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    instance.debug(message, error, stackTrace);
  }

  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    instance.info(message, error, stackTrace);
  }

  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    instance.warning(message, error, stackTrace);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    instance.error(message, error, stackTrace);
  }

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '🐛 DEBUG: $message',
      name: 'SmartPublisher',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log('💡 INFO: $message', name: 'SmartPublisher');
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '⚠️ WARNING: $message',
      name: 'SmartPublisher',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      '🚨 ERROR: $message',
      name: 'SmartPublisher',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
