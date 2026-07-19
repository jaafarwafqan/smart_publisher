import '../result/app_result.dart';

abstract class BaseUseCase<Params, ReturnType> {
  const BaseUseCase();

  Future<AppResult<ReturnType>> call(Params params);
}
