import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository
    extends BaseRepository<NotificationEntity> {
  const NotificationRepository();

  Future<AppResult<List<NotificationEntity>>> getNotifications();
  Future<AppResult<void>> markAsRead(String id);
  Future<AppResult<void>> markAllAsRead();
}
