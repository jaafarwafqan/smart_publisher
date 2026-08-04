import '../../../../core/base/base_entity.dart';

class ScheduleEntity extends BaseEntity {
  const ScheduleEntity({
    required this.id,
    required this.postId,
    required this.title,
    required this.status,
    required this.scheduledAt,
  });

  @override
  final String id;
  final String postId;
  final String title;
  final String status;
  final DateTime scheduledAt;
}
