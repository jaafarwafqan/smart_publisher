import 'package:dio/dio.dart';
import 'package:smart_publisher/src/core/network/network_client.dart';

class FakeNetworkClient implements NetworkClient {
  FakeNetworkClient({
    this.getHandler,
    this.postHandler,
    this.putHandler,
    this.patchHandler,
    this.deleteHandler,
    this.uploadHandler,
  });

  final Future<Response<dynamic>> Function(String path)? getHandler;
  final Future<Response<dynamic>> Function(String path, dynamic data)?
  postHandler;
  final Future<Response<dynamic>> Function(String path, dynamic data)?
  putHandler;
  final Future<Response<dynamic>> Function(String path, dynamic data)?
  patchHandler;
  final Future<Response<dynamic>> Function(String path, dynamic data)?
  deleteHandler;
  final Future<Response<dynamic>> Function(String path, FormData formData)?
  uploadHandler;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) async {
    if (getHandler != null) {
      return getHandler!(path);
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{},
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> post(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) async {
    if (postHandler != null) {
      return postHandler!(path, data);
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{},
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> put(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) async {
    if (putHandler != null) {
      return putHandler!(path, data);
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{},
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> patch(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) async {
    if (patchHandler != null) {
      return patchHandler!(path, data);
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{},
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> delete(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
  }) async {
    if (deleteHandler != null) {
      return deleteHandler!(path, data);
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{},
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> upload(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    int? timeoutInSeconds,
    int maxRetries = 3,
  }) async {
    if (uploadHandler != null) {
      return uploadHandler!(path, formData);
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{},
      statusCode: 200,
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
  }) async {
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: <String, dynamic>{'save_path': savePath},
      statusCode: 200,
    );
  }

  @override
  Future<Response<dynamic>> requestWithRetry(
    Future<Response<dynamic>> Function() request, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    return request();
  }
}
