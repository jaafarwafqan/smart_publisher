import 'package:dio/dio.dart';

import '../network/backend_error_message.dart';
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
      // The backend always returns a real, already-localized reason (see
      // bootstrap/app.php's exception renderer + backend_error_message.dart's
      // docblock) — falling back to the caller's generic fallbackMessage
      // only when there's genuinely no response to read one from (e.g. a
      // connection timeout that never reached the server).
      final message =
          extractBackendErrorMessage(error.response?.data, statusCode) ??
          fallbackMessage;
      if (statusCode == 401) {
        return AuthenticationFailure(
          message: message,
          exception: error,
          stackTrace: stackTrace,
          code: 'AUTH_401',
        );
      }
      if (statusCode == 403) {
        return AuthorizationFailure(
          message: message,
          exception: error,
          stackTrace: stackTrace,
          code: 'AUTHZ_403',
        );
      }
      if ((statusCode ?? 0) >= 500) {
        return ServerFailure(
          message: message,
          exception: error,
          stackTrace: stackTrace,
          code: 'SERVER_${statusCode ?? 500}',
        );
      }
      return NetworkFailure(
        message: message,
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
