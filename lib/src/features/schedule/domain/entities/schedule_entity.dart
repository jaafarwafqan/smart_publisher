import '../../../../core/base/base_entity.dart';

class ScheduleEntity extends BaseEntity {
  const ScheduleEntity({
    required this.id,
    required this.postId,
    required this.scheduledAt,
    this.isActive = true,
  });

  @override
  final String id;
  final String postId;
  final DateTime scheduledAt;
  final bool isActive;
}
