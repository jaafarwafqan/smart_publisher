import 'package:dio/dio.dart';

abstract interface class NetworkClient {
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  });

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  });

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  });

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  });

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  });

  Future<Response<dynamic>> upload(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
    int maxRetries = 3,
  });

  Future<Response<dynamic>> download(
    String path, {
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
    int maxRetries = 3,
  });

  Future<Response<dynamic>> requestWithRetry(
    Future<Response<dynamic>> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  });
}
