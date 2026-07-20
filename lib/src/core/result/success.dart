import 'app_result.dart';

class Success<T> extends AppResult<T> {
  const Success(this.data, {this.message});

  @override
  final T? data;

  @override
  final String? message;

  @override
  final Object? exception = null;

  @override
  final AppFailure? failure = null;

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;
}
