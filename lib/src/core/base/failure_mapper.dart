import 'package:dio/dio.dart';

import '../result/app_failure.dart';

abstract interface class FailureMapper {
  AppFailure map(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  });
}

class DefaultFailureMapper implements FailureMapper {
  const DefaultFailureMapper();

  @override
  AppFailure map(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        return AuthenticationFailure(
          message: fallbackMessage,
          exception: error,
          stackTrace: stackTrace,
          code: 'AUTH_401',
        );
      }
      if (statusCode == 403) {
        return AuthorizationFailure(
          message: fallbackMessage,
          exception: error,
          stackTrace: stackTrace,
          code: 'AUTHZ_403',
        );
      }
      if ((statusCode ?? 0) >= 500) {
        return ServerFailure(
          message: fallbackMessage,
          exception: error,
          stackTrace: stackTrace,
          code: 'SERVER_${statusCode ?? 500}',
        );
      }
      return NetworkFailure(
        message: fallbackMessage,
        exception: error,
        stackTrace: stackTrace,
        code: 'NETWORK',
      );
    }

    if (error is StateError) {
      final message = error.message.toString().toLowerCase();
      if (message.contains('not found') || message.contains('invalid')) {
        return ValidationFailure(
          message: fallbackMessage,
          exception: error,
          stackTrace: stackTrace,
          code: 'VALIDATION',
        );
      }
    }

    return UnknownFailure(
      message: fallbackMessage,
      exception: error,
      stackTrace: stackTrace,
      code: 'UNKNOWN',
    );
  }
}
