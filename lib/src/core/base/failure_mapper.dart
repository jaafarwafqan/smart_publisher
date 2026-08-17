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
      if (statusCode == 422) {
        return ValidationFailure(
          message: message,
          exception: error,
          stackTrace: stackTrace,
          code: 'VALIDATION_422',
          fieldErrors: _extractFieldErrors(error.response?.data),
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

  /// Parses Laravel's 422 `errors` object (`{"field": ["msg", ...]}`) into
  /// a typed map, tolerating the shapes actually seen in practice — a
  /// single string per field, not just a list — same leniency
  /// [extractBackendErrorMessage] already applies. Returns null (not an
  /// empty map) when there's nothing usable, so callers can tell "no
  /// field-level detail was sent" apart from "sent, but empty".
  Map<String, List<String>>? _extractFieldErrors(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return null;
    }

    final errors = responseData['errors'];
    if (errors is! Map<String, dynamic>) {
      return null;
    }

    final result = <String, List<String>>{};
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List) {
        final messages = value.whereType<String>().toList(growable: false);
        if (messages.isNotEmpty) {
          result[entry.key] = messages;
        }
      } else if (value is String && value.isNotEmpty) {
        result[entry.key] = <String>[value];
      }
    }

    return result.isEmpty ? null : result;
  }
}
