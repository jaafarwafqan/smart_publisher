export 'failure.dart';
export 'success.dart';

abstract class AppResult<T> {
  const AppResult();

  bool get isSuccess;
  bool get isFailure;

  T? get data;
  String? get message;
  Object? get exception;
}
