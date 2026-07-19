import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';

class GenerateAiText extends BaseUseCase<String, String> {
  const GenerateAiText();

  @override
  Future<AppResult<String>> call(String params) async {
    return Success<String>('Generated AI text for: $params');
  }
}
