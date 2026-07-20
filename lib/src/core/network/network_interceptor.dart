import 'package:dio/dio.dart';

import '../logger/app_logger.dart';
import '../observability/error_correlation.dart';
import '../observability/metrics_registry.dart';
import '../observability/trace_context.dart';
import '../security/scope_authorizer.dart';
import '../security/token_lifecycle_manager.dart';

abstract interface class NetworkInterceptor {
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  );
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  );
  Future<void> onError(DioException error, ErrorInterceptorHandler handler);
}

class AuthorizationInterceptor implements NetworkInterceptor {
  const AuthorizationInterceptor({
    this.tokenProvider,
    this.tokenLifecycleManager,
    this.scopeAuthorizer,
    this.requiredScopesResolver,
  });

  final Future<String?> Function()? tokenProvider;
  final TokenLifecycleManager? tokenLifecycleManager;
  final ScopeAuthorizer? scopeAuthorizer;
  final Set<String> Function(RequestOptions options)? requiredScopesResolver;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiredScopes =
        requiredScopesResolver?.call(options) ?? const <String>{};
    if (requiredScopes.isNotEmpty &&
        scopeAuthorizer != null &&
        tokenLifecycleManager != null) {
      final tokens = await tokenLifecycleManager!.readTokens();
      final grantedScopes = tokens?.scopes ?? const <String>{};
      final authorized = scopeAuthorizer!.hasScopes(
        grantedScopes: grantedScopes,
        requiredScopes: requiredScopes,
      );
      if (!authorized) {
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 403,
              statusMessage: 'Insufficient OAuth scopes',
            ),
            error: 'Insufficient OAuth scopes',
          ),
        );
        return;
      }
    }

    final token = tokenLifecycleManager != null
        ? await tokenLifecycleManager!.getValidAccessToken()
        : await tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    handler.next(error);
  }
}

class LoggingInterceptor implements NetworkInterceptor {
  const LoggingInterceptor();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final traceId = TraceContext.currentTraceId() ?? TraceContext.newTraceId();
    options.extra['traceId'] = traceId;
    options.extra['requestStartAt'] = DateTime.now().microsecondsSinceEpoch;
    options.headers['X-Trace-Id'] = traceId;

    globalMetricsRegistry.increment('http.requests.total');
    globalMetricsRegistry.increment(
      'http.requests.${options.method.toLowerCase()}',
    );

    AppLogger.structured(
      'INFO',
      'HTTP request start',
      context: <String, Object?>{
        'trace_id': traceId,
        'method': options.method,
        'uri': options.uri.toString(),
      },
    );
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final started = response.requestOptions.extra['requestStartAt'] as int?;
    final duration = started == null
        ? Duration.zero
        : Duration(
            microseconds: DateTime.now().microsecondsSinceEpoch - started,
          );
    globalMetricsRegistry.recordDuration('http.request.duration', duration);

    final traceId =
        (response.requestOptions.extra['traceId'] as String?) ??
        TraceContext.currentTraceId() ??
        TraceContext.newTraceId();

    AppLogger.structured(
      'INFO',
      'HTTP request success',
      context: <String, Object?>{
        'trace_id': traceId,
        'status': response.statusCode,
        'method': response.requestOptions.method,
        'uri': response.requestOptions.uri.toString(),
        'duration_ms': duration.inMilliseconds,
      },
    );
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final started = error.requestOptions.extra['requestStartAt'] as int?;
    final duration = started == null
        ? Duration.zero
        : Duration(
            microseconds: DateTime.now().microsecondsSinceEpoch - started,
          );
    globalMetricsRegistry.increment('http.errors.total');
    globalMetricsRegistry.recordDuration('http.request.duration', duration);

    final traceId =
        (error.requestOptions.extra['traceId'] as String?) ??
        TraceContext.currentTraceId() ??
        TraceContext.newTraceId();
    final correlationId = correlateError(error, error.stackTrace);

    AppLogger.structured(
      'ERROR',
      'HTTP request failure',
      error: error,
      stackTrace: error.stackTrace,
      context: <String, Object?>{
        'trace_id': traceId,
        'correlation_id': correlationId,
        'status': error.response?.statusCode,
        'method': error.requestOptions.method,
        'uri': error.requestOptions.uri.toString(),
        'duration_ms': duration.inMilliseconds,
      },
    );
    handler.next(error);
  }
}

class RetryInterceptor implements NetworkInterceptor {
  const RetryInterceptor({
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 1),
  });

  final int maxRetries;
  final Duration delay;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      if (error.requestOptions.extra['retryCount'] == null) {
        error.requestOptions.extra['retryCount'] = 0;
      }
      final retryCount = error.requestOptions.extra['retryCount'] as int;
      if (retryCount < maxRetries) {
        error.requestOptions.extra['retryCount'] = retryCount + 1;
        await Future<void>.delayed(delay);
        handler.resolve(await Dio().fetch(error.requestOptions));
        return;
      }
    }
    handler.next(error);
  }
}

class RefreshTokenInterceptor implements NetworkInterceptor {
  const RefreshTokenInterceptor({
    this.refreshTokenProvider,
    this.tokenLifecycleManager,
  });

  final Future<String?> Function()? refreshTokenProvider;
  final TokenLifecycleManager? tokenLifecycleManager;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = error.response?.statusCode == 401;
    final alreadyRetried = error.requestOptions.extra['tokenRefreshed'] == true;
    if (isUnauthorized && !alreadyRetried) {
      final refreshedToken = tokenLifecycleManager != null
          ? await tokenLifecycleManager!.refreshAccessToken()
          : await refreshTokenProvider?.call();

      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        error.requestOptions.extra['tokenRefreshed'] = true;
        error.requestOptions.headers['Authorization'] =
            'Bearer $refreshedToken';
        handler.resolve(await Dio().fetch(error.requestOptions));
        return;
      }
    }
    handler.next(error);
  }
}

class RateLimiterInterceptor implements NetworkInterceptor {
  RateLimiterInterceptor({this.maxRequestsPerSecond = 5});

  final int maxRequestsPerSecond;
  final _RateLimiter _rateLimiter = _RateLimiter();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _rateLimiter.acquire(maxRequestsPerSecond);
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    handler.next(error);
  }
}

class _RateLimiter {
  final List<DateTime> _timestamps = <DateTime>[];

  Future<void> acquire(int maxRequestsPerSecond) async {
    final now = DateTime.now();
    _timestamps.removeWhere(
      (timestamp) => now.difference(timestamp).inSeconds >= 1,
    );
    if (_timestamps.length >= maxRequestsPerSecond) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await acquire(maxRequestsPerSecond);
      return;
    }
    _timestamps.add(now);
  }
}
