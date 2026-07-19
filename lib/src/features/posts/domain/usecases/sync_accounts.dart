import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';

class SyncAccounts extends BaseUseCase<void, List<String>> {
  const SyncAccounts();

  @override
  Future<AppResult<List<String>>> call(void params) async {
    return const Success<List<String>>([
      'facebook',
      'instagram',
    ], message: 'Accounts synced');
  }
}
