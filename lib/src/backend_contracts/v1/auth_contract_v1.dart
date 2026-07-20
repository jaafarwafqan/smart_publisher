class LoginRequestDtoV1 {
  const LoginRequestDtoV1({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'email': email, 'password': password};
  }
}

String _stringValue(Object? value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

class RefreshTokenRequestDtoV1 {
  const RefreshTokenRequestDtoV1({required this.refreshToken});

  final String refreshToken;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'refresh_token': refreshToken};
  }
}

class AuthUserDtoV1 {
  const AuthUserDtoV1({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  final String id;
  final String name;
  final String email;
  final String? role;

  factory AuthUserDtoV1.fromJson(Map<String, dynamic> json) {
    return AuthUserDtoV1(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      email: _stringValue(json['email']),
      role: json['role']?.toString(),
    );
  }
}

class LoginResponseDtoV1 {
  const LoginResponseDtoV1({
    required this.accessToken,
    this.refreshToken,
    required this.user,
    this.expiresIn = 3600,
    this.scope = '',
  });

  final String accessToken;
  final String? refreshToken;
  final AuthUserDtoV1 user;
  final int expiresIn;
  final String scope;

  factory LoginResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return LoginResponseDtoV1(
      accessToken: _stringValue(json['access_token']),
      refreshToken: json['refresh_token']?.toString(),
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      scope: _stringValue(json['scope']),
      user: AuthUserDtoV1.fromJson(
        (json['user'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      ),
    );
  }
}

class RefreshTokenResponseDtoV1 {
  const RefreshTokenResponseDtoV1({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn = 3600,
    this.scope = '',
  });

  final String accessToken;
  final String? refreshToken;
  final int expiresIn;
  final String scope;

  factory RefreshTokenResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseDtoV1(
      accessToken: _stringValue(json['access_token']),
      refreshToken: json['refresh_token']?.toString(),
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      scope: _stringValue(json['scope']),
    );
  }
}
