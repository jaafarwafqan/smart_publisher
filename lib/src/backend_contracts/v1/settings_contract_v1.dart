String _settingsAsString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

bool _settingsAsBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

int _settingsAsInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

class SettingsResponseDtoV1 {
  const SettingsResponseDtoV1({
    required this.timezone,
    required this.locale,
    required this.notificationsEnabled,
    required this.dailyDigestHour,
  });

  final String timezone;
  final String locale;
  final bool notificationsEnabled;
  final int dailyDigestHour;

  factory SettingsResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return SettingsResponseDtoV1(
      timezone: _settingsAsString(json['timezone'], fallback: 'UTC'),
      locale: _settingsAsString(json['locale'], fallback: 'en'),
      notificationsEnabled: _settingsAsBool(
        json['notifications_enabled'],
        fallback: true,
      ),
      dailyDigestHour: _settingsAsInt(json['daily_digest_hour'], fallback: 9),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timezone': timezone,
      'locale': locale,
      'notifications_enabled': notificationsEnabled,
      'daily_digest_hour': dailyDigestHour,
    };
  }
}
