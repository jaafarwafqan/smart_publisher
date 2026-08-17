abstract class AppFailure {
  const AppFailure({
    required this.message,
    this.exception,
    this.stackTrace,
    this.code,
  });

  final String message;
  final Object? exception;
  final StackTrace? stackTrace;
  final String? code;
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.message,
    super.exception,
    super.stackTrace,
    super.code,
  });
}

class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    super.exception,
    super.stackTrace,
    super.code,
    this.fieldErrors,
  });

  /// Raw per-field messages from Laravel's 422 `errors` object
  /// (`{"email": ["The email has already been taken."]}`), when the
  /// failure came from a real validation response — null for the local
  /// offline-draft `StateError` path, which has no field shape to offer.
  /// [AppFailure.message] already holds the first field's message (see
  /// `extractBackendErrorMessage`) for callers that only show one string;
  /// this is here for a caller that wants to highlight every field at once.
  final Map<String, List<String>>? fieldErrors;
}

class AuthenticationFailure extends AppFailure {
  const AuthenticationFailure({
    required super.message,
    super.exception,
    super.stackTrace,
    super.code,
  });
}

class AuthorizationFailure extends AppFailure {
  const AuthorizationFailure({
    required super.message,
    super.exception,
    super.stackTrace,
    super.code,
  });
}

class ServerFailure extends AppFailure {
  const ServerFailure({
    required super.message,
    super.exception,
    super.stackTrace,
    super.code,
  });
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({
    required super.message,
    super.exception,
    super.stackTrace,
    super.code,
  });
}
