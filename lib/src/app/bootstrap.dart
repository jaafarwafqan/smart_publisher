import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/src/core/logger/app_logger.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // 1. التقاط الأخطاء غير المعالجة في Flutter
  FlutterError.onError = (details) {
    AppLogger.e('Flutter Error', details.exception, details.stack);
  };

  // 2. التقاط الأخطاء على مستوى النظام
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.e('Platform Error', error, stack);
    return true;
  };

  // 3. تهيئة بيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 4. تشغيل التطبيق داخل Zone لحماية الـ App من الانهيار بسبب أي خطأ
  await runZonedGuarded(
    () async {
      // هنا سنقوم لاحقاً باستدعاء دوال التهيئة (Storage, Database, etc)

      runApp(ProviderScope(child: await builder()));
    },
    (error, stack) {
      AppLogger.e('Zone Error', error, stack);
    },
  );
}
