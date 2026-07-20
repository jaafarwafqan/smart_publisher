String _usersAsString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

bool _usersAsBool(Object? value, {bool fallback = false}) {
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

class UserResponseDtoV1 {
  const UserResponseDtoV1({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'guest',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  factory UserResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return UserResponseDtoV1(
      id: _usersAsString(json['id']),
      name: _usersAsString(json['name']),
      email: _usersAsString(json['email']),
      role: _usersAsString(json['role'], fallback: 'guest'),
      isActive: _usersAsBool(json['is_active'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
    };
  }
}
