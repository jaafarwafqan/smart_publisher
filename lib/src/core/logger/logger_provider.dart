import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_logger.dart';
import 'logger_service.dart';

// نستخدم الواجهة (LoggerService) كنوع البيانات المُرجع لتطبيق مبدأ (Dependency Inversion)
final loggerProvider = Provider<LoggerService>((ref) {
  return AppLogger.instance;
});
