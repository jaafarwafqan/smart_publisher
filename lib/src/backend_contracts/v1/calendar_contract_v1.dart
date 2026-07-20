String _calendarAsString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

List<String> _calendarAsStringList(Object? value) {
  if (value is List<dynamic>) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

DateTime? _calendarAsDateTime(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class CalendarEntryResponseDtoV1 {
  const CalendarEntryResponseDtoV1({
    required this.postId,
    required this.title,
    required this.status,
    required this.platforms,
    this.scheduledAt,
  });

  final String postId;
  final String title;
  final String status;
  final List<String> platforms;
  final DateTime? scheduledAt;

  factory CalendarEntryResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return CalendarEntryResponseDtoV1(
      postId: _calendarAsString(json['post_id']),
      title: _calendarAsString(json['title']),
      status: _calendarAsString(json['status'], fallback: 'draft'),
      platforms: _calendarAsStringList(json['platforms']),
      scheduledAt: _calendarAsDateTime(json['scheduled_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'post_id': postId,
      'title': title,
      'status': status,
      'platforms': platforms,
      'scheduled_at': scheduledAt?.toIso8601String(),
    };
  }
}
