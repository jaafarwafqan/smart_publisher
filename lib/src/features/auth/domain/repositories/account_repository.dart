import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/account_entity.dart';

abstract class AccountRepository extends BaseRepository<AccountEntity> {
  const AccountRepository();

  Future<AppResult<List<AccountEntity>>> getAccounts();
  Future<AppResult<AccountEntity>> connectAccount(AccountEntity account);
  Future<AppResult<void>> disconnectAccount(String id);
}
