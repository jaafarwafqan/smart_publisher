import 'package:dio/dio.dart';

import 'network_client.dart';
import 'network_interceptor.dart';

class DioNetworkClient implements NetworkClient {
  DioNetworkClient({
    Dio? dio,
    List<NetworkInterceptor> interceptors = const <NetworkInterceptor>[],
  }) : _dio = dio ?? Dio(BaseOptions()) {
    for (final interceptor in interceptors) {
      _dio.interceptors.add(_InterceptorAdapter(interceptor));
    }
  }

  final Dio _dio;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) {
    return requestWithRetry(() {
      return _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _withTimeout(options, timeoutInSeconds),
      );
    });
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) {
    return requestWithRetry(() {
      return _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withTimeout(options, timeoutInSeconds),
      );
    });
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) {
    return requestWithRetry(() {
      return _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withTimeout(options, timeoutInSeconds),
      );
    });
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) {
    return requestWithRetry(() {
      return _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withTimeout(options, timeoutInSeconds),
      );
    });
  }

  @override
  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) {
    return requestWithRetry(() {
      return _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _withTimeout(options, timeoutInSeconds),
      );
    });
  }

  @override
  Future<Response<dynamic>> upload(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
    int maxRetries = 3,
  }) {
    return requestWithRetry(
      () => _dio.post<dynamic>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: _withTimeout(options, timeoutInSeconds),
      ),
      maxRetries: maxRetries,
    );
  }

  @override
  Future<Response<dynamic>> download(
    String path, {
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
    int maxRetries = 3,
  }) {
    return requestWithRetry(
      () => _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        options: _withTimeout(options, timeoutInSeconds),
      ),
      maxRetries: maxRetries,
    );
  }

  @override
  Future<Response<dynamic>> requestWithRetry(
    Future<Response<dynamic>> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await request();
      } catch (error) {
        attempt += 1;
        if (attempt >= maxRetries) {
          rethrow;
        }
        await Future<void>.delayed(delay);
      }
    }
  }

  Options? _withTimeout(Options? options, int? timeoutInSeconds) {
    if (timeoutInSeconds == null) {
      return options;
    }

    return (options ?? Options()).copyWith(
      receiveTimeout: Duration(seconds: timeoutInSeconds),
    );
  }
}

class _InterceptorAdapter extends Interceptor {
  _InterceptorAdapter(this.interceptor);

  final NetworkInterceptor interceptor;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    interceptor.onRequest(options, handler);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    interceptor.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    interceptor.onError(err, handler);
  }
}
