import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';

class DeleteDraft extends BaseUseCase<String, void> {
  const DeleteDraft();

  @override
  Future<AppResult<void>> call(String params) async {
    return const Success<void>(null, message: 'Draft deleted');
  }
}
