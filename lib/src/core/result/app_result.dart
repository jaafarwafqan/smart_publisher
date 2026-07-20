import 'app_failure.dart';

export 'app_failure.dart';
export 'failure.dart';
export 'success.dart';

abstract class AppResult<T> {
  const AppResult();

  bool get isSuccess;
  bool get isFailure;

  T? get data;
  String? get message;
  Object? get exception;
  AppFailure? get failure;
}
