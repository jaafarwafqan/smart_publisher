import 'app_result.dart';

class Failure<T> extends AppResult<T> {
  const Failure(this.message, {this.exception, this.data, this.failure});

  Failure.fromFailure(this.failure, {this.data})
    : message = failure?.message,
      exception = failure?.exception;

  @override
  final String? message;

  @override
  final Object? exception;

  @override
  final T? data;

  @override
  final AppFailure? failure;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;
}
