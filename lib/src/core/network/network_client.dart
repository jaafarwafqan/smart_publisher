import 'package:dio/dio.dart';

abstract interface class NetworkClient {
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });
}
