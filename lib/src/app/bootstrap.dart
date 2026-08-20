import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:smart_publisher/src/core/logger/app_logger.dart';
import 'package:smart_publisher/src/core/observability/crash_reporter.dart';
import 'package:smart_publisher/src/core/observability/error_correlation.dart';
import 'package:smart_publisher/src/core/observability/trace_context.dart';
import 'package:smart_publisher/src/core/observability/sentry_config.dart';
import 'package:smart_publisher/src/core/performance/background_task_manager.dart';
import 'package:smart_publisher/src/core/performance/image_cache_manager.dart';
import 'package:smart_publisher/src/core/performance/startup_profiler.dart';
import 'package:smart_publisher/src/core/network/laravel_api.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // Was `final crashReporter = await _createCrashReporter();` — a real
  // Sentry.init() does native-channel setup and SDK bootstrapping, and
  // awaiting it here serialized that work in front of runApp() on every
  // single release-build cold start, not just the rare crash-reporting
  // path. crashReporter starts as the free, synchronous ConsoleCrashReporter
  // and is swapped in-place once Sentry.init resolves, in the background —
  // every closure below captures the variable itself (Dart closures capture
  // by reference), so FlutterError.onError etc. automatically pick up
  // SentryCrashReporter the moment it's ready, with no restructuring needed.
  // Same "telemetry must never gate the app" reasoning _createCrashReporter
  // already applied to a failed init now also applies to a slow one.
  CrashReporter crashReporter = const ConsoleCrashReporter();
  unawaited(
    _createCrashReporter().then((reporter) => crashReporter = reporter),
  );
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
        try {
          LaravelApi.assertReleaseConfiguration();
        } on StateError catch (error) {
          // A live visual review caught this: an incomplete/non-HTTPS
          // release configuration made the whole app a permanent blank
          // white screen with zero on-screen feedback — the StateError
          // thrown here used to propagate straight to runZonedGuarded's
          // handler below, which only logs, and runApp() was never called
          // at all since this check runs before it. A misconfigured
          // deployment must fail loud and visible, not silently render
          // nothing. Deliberately self-contained (no l10n/network/DI
          // dependency) since this exists specifically for the case where
          // something about the app's own configuration is broken.
          runApp(ReleaseConfigurationErrorApp(message: error.message));
          StartupProfiler.instance.markReady();
          return;
        }
        // Required for DateFormat (used for locale-correct Arabic/English
        // date/month names, e.g. dashboard/recent-activity subtitles) —
        // without this, DateFormat throws for any non-English locale.
        await initializeDateFormatting();
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

Future<CrashReporter> _createCrashReporter() async {
  if (!SentryConfig.isEnabled) {
    return const ConsoleCrashReporter();
  }

  try {
    await Sentry.init((options) {
      options
        ..dsn = SentryConfig.dsn
        ..environment = SentryConfig.environment
        ..attachStacktrace = true
        ..sendDefaultPii = false;
    });
    return const SentryCrashReporter();
  } catch (error, stackTrace) {
    // Error telemetry is never allowed to make the app unavailable. The
    // fallback retains the full local diagnostic signal if the SDK/DSN is
    // misconfigured during a release. Paired with AppLogger.structured, same
    // as every other error site in this file (FlutterError.onError,
    // PlatformDispatcher.instance.onError, the zone error handler below) —
    // this one previously only reached ConsoleCrashReporter's print(),
    // skipping the structured/JSON log every other failure mode gets.
    AppLogger.structured(
      'ERROR',
      'Sentry initialization failed',
      error: error,
      stackTrace: stackTrace,
      context: const <String, Object?>{'stage': 'sentry_initialization'},
    );
    await const ConsoleCrashReporter().record(
      error,
      stackTrace,
      context: const <String, Object?>{'stage': 'sentry_initialization'},
    );
    return const ConsoleCrashReporter();
  }
}

/// Shown instead of the app itself when [LaravelApi.assertReleaseConfiguration]
/// rejects a release build's endpoints — see bootstrap()'s catch block
/// above. Deliberately a minimal, self-contained [MaterialApp]: no
/// Riverpod ProviderScope, no localization delegate, no network/DI setup
/// of any kind, since this exists precisely for the case where the app's
/// own configuration can't be trusted. Bilingual (not ARB-driven) for the
/// same reason.
class ReleaseConfigurationErrorApp extends StatelessWidget {
  const ReleaseConfigurationErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1B2E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.settings_suggest_outlined,
                  color: Colors.amberAccent,
                  size: 56,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Configuration error — إعداد غير صحيح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This build is missing valid HTTPS backend endpoints and '
                  'cannot start. Contact the release/deployment team.\n'
                  'هذه النسخة تفتقد لعناوين خادم صحيحة عبر HTTPS ولا يمكنها '
                  'العمل. تواصل مع فريق النشر.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
