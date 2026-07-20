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
  });
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
