import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/src/core/logger/app_logger.dart';

export 'package:smart_publisher/src/core/theme/theme_provider.dart';

final dioProvider = Provider((ref) => "Dio Instance");
final loggerProvider = Provider((ref) => AppLogger.instance);
