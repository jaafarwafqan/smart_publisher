import 'package:dio/dio.dart';

import 'network_client.dart';

class DioNetworkClient implements NetworkClient {
  DioNetworkClient({Dio? dio}) : _dio = dio ?? Dio(BaseOptions());

  final Dio _dio;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get<dynamic>(path, queryParameters: queryParameters);
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.post<dynamic>(
      path,
      data: data,
      queryParameters: queryParameters,
    );
  }
}
