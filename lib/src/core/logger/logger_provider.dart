import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_logger.dart';
import 'logger_service.dart';

part 'logger_provider.g.dart';

// نستخدم الواجهة (LoggerService) كنوع البيانات المُرجع لتطبيق مبدأ (Dependency Inversion)
@Riverpod(keepAlive: true)
LoggerService logger(LoggerRef ref) {
  return const AppLogger();
}
