class LoginRequestDtoV1 {
  const LoginRequestDtoV1({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'email': email, 'password': password};
  }
}

/// Sprint 4 (Commercial SaaS): public self-registration.
class RegisterRequestDtoV1 {
  const RegisterRequestDtoV1({
    required this.name,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
  });

  final String name;
  final String email;
  final String password;
  final String passwordConfirmation;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
  }
}

class ForgotPasswordRequestDtoV1 {
  const ForgotPasswordRequestDtoV1({required this.email});

  final String email;

  Map<String, dynamic> toJson() => <String, dynamic>{'email': email};
}

class ResetPasswordRequestDtoV1 {
  const ResetPasswordRequestDtoV1({
    required this.email,
    required this.token,
    required this.password,
    required this.passwordConfirmation,
  });

  final String email;
  final String token;
  final String password;
  final String passwordConfirmation;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'email': email,
      'token': token,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
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

/// Sprint 4 (Commercial SaaS): the subset of GET /me's `user` object the
/// two-factor setup screen needs — whether 2FA is already confirmed for
/// this account. There is no dedicated "my 2FA status" endpoint; this
/// reuses the existing /me contract instead of adding one.
class CurrentUserStatusDtoV1 {
  const CurrentUserStatusDtoV1({
    required this.twoFactorEnabled,
    required this.emailVerified,
  });

  final bool twoFactorEnabled;
  final bool emailVerified;

  factory CurrentUserStatusDtoV1.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : <String, dynamic>{};
    return CurrentUserStatusDtoV1(
      twoFactorEnabled: userMap['two_factor_enabled'] == true,
      emailVerified: userMap['email_verified'] == true,
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
