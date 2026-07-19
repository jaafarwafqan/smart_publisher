class ScheduleValidator {
  const ScheduleValidator();

  String? validate(DateTime? scheduledAt) {
    if (scheduledAt == null) {
      return 'Schedule time is required.';
    }

    if (!scheduledAt.isAfter(DateTime.now())) {
      return 'Schedule time must be in the future.';
    }

    return null;
  }
}
