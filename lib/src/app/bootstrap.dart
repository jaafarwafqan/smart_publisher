import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_publisher/src/core/logger/app_logger.dart';
import 'package:smart_publisher/src/core/observability/crash_reporter.dart';
import 'package:smart_publisher/src/core/observability/error_correlation.dart';
import 'package:smart_publisher/src/core/observability/trace_context.dart';
import 'package:smart_publisher/src/core/performance/background_task_manager.dart';
import 'package:smart_publisher/src/core/performance/image_cache_manager.dart';
import 'package:smart_publisher/src/core/performance/startup_profiler.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  const crashReporter = ConsoleCrashReporter();
  const imageCacheManager = ImageCacheManager();
  final backgroundTaskManager = BackgroundTaskManager();

  // 1. التقاط الأخطاء غير المعالجة في Flutter
  FlutterError.onError = (details) {
    final traceId = TraceContext.currentTraceId() ?? TraceContext.newTraceId();
    final correlationId = correlateError(details.exception, details.stack);
    AppLogger.structured(
      'ERROR',
      'Flutter Error',
      error: details.exception,
      stackTrace: details.stack,
      context: <String, Object?>{
        'trace_id': traceId,
        'correlation_id': correlationId,
        'stage': 'flutter_error',
      },
    );
    unawaited(
      crashReporter.record(
        details.exception,
        details.stack ?? StackTrace.current,
        traceId: traceId,
        correlationId: correlationId,
      ),
    );
  };

  // 2. التقاط الأخطاء على مستوى النظام
  PlatformDispatcher.instance.onError = (error, stack) {
    final traceId = TraceContext.currentTraceId() ?? TraceContext.newTraceId();
    final correlationId = correlateError(error, stack);
    AppLogger.structured(
      'ERROR',
      'Platform Error',
      error: error,
      stackTrace: stack,
      context: <String, Object?>{
        'trace_id': traceId,
        'correlation_id': correlationId,
        'stage': 'platform_error',
      },
    );
    unawaited(
      crashReporter.record(
        error,
        stack,
        traceId: traceId,
        correlationId: correlationId,
      ),
    );
    return true;
  };

  // 3. تشغيل التطبيق داخل Zone لحماية الـ App من الانهيار بسبب أي خطأ
  final bootstrapTraceId =
      TraceContext.currentTraceId() ?? TraceContext.newTraceId();

  await TraceContext.runWithTrace(
    () => runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();
        imageCacheManager.configure(
          maxEntries: 120,
          maxBytes: 120 * 1024 * 1024,
        );

        backgroundTaskManager.schedulePeriodic(const Duration(seconds: 30), () {
          final snapshot = imageCacheManager.snapshot();
          AppLogger.structured(
            'DEBUG',
            'Image cache snapshot',
            context: <String, Object?>{
              'image_cache_entries': snapshot.currentSize,
              'image_cache_bytes': snapshot.currentSizeBytes,
            },
          );
        });

        // هنا سنقوم لاحقاً باستدعاء دوال التهيئة (Storage, Database, etc)

        final app = await builder();
        runApp(ProviderScope(child: app));
        StartupProfiler.instance.markReady();
      },
      (error, stack) {
        final traceId =
            TraceContext.currentTraceId() ?? TraceContext.newTraceId();
        final correlationId = correlateError(error, stack);
        AppLogger.structured(
          'ERROR',
          'Zone Error',
          error: error,
          stackTrace: stack,
          context: <String, Object?>{
            'trace_id': traceId,
            'correlation_id': correlationId,
            'stage': 'zone_error',
          },
        );
        unawaited(
          crashReporter.record(
            error,
            stack,
            traceId: traceId,
            correlationId: correlationId,
          ),
        );
      },
    ),
    traceId: bootstrapTraceId,
  );
}
