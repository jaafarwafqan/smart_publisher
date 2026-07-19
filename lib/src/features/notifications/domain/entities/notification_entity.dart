import '../../../../core/base/base_entity.dart';

class NotificationEntity extends BaseEntity {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    this.isRead = false,
  });

  @override
  final String id;
  final String title;
  final String body;
  final bool isRead;
}
