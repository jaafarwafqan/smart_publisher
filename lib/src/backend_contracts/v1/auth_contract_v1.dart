class LoginRequestDtoV1 {
  const LoginRequestDtoV1({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'email': email, 'password': password};
  }
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
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: json['role'] as String?,
    );
  }
}

class LoginResponseDtoV1 {
  const LoginResponseDtoV1({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.expiresIn = 3600,
    this.scope = '',
  });

  final String accessToken;
  final String refreshToken;
  final AuthUserDtoV1 user;
  final int expiresIn;
  final String scope;

  factory LoginResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return LoginResponseDtoV1(
      accessToken: (json['access_token'] ?? '') as String,
      refreshToken: (json['refresh_token'] ?? '') as String,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      scope: (json['scope'] ?? '') as String,
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
      accessToken: (json['access_token'] ?? '') as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 3600,
      scope: (json['scope'] ?? '') as String,
    );
  }
}
