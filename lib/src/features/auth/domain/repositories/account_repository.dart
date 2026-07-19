import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/user_entity.dart';

abstract class AccountRepository extends BaseRepository<UserEntity> {
  const AccountRepository();

  Future<AppResult<List<UserEntity>>> getAccounts();
  Future<AppResult<UserEntity>> connectAccount(UserEntity account);
  Future<AppResult<void>> disconnectAccount(String id);
}
