import '../../features/schedule/domain/entities/schedule_entity.dart';
import '../validators/schedule_validator.dart';

class SchedulePolicy {
  const SchedulePolicy({this.validator = const ScheduleValidator()});

  final ScheduleValidator validator;

  String? validateSchedule(ScheduleEntity? schedule) {
    if (schedule == null) {
      return 'Schedule is required.';
    }

    return validator.validate(schedule.scheduledAt);
  }
}
