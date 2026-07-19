import 'app_result.dart';

class Failure<T> extends AppResult<T> {
  const Failure(this.message, {this.exception, this.data});

  @override
  final String? message;

  @override
  final Object? exception;

  @override
  final T? data;

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;
}
