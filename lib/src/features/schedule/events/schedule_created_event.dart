import '../../../core/events/event.dart';

class ScheduleCreatedEvent extends AppEvent {
  const ScheduleCreatedEvent({required this.postId, required this.scheduledAt});

  final String postId;
  final DateTime? scheduledAt;

  @override
  String get type => 'schedule_created';
}
