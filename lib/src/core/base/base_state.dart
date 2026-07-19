abstract class BaseState<T> {
  const BaseState();

  T get data;
  bool get isLoading;
  String? get errorMessage;
}
