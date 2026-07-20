class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
    this.expiresAt,
    this.permissions = const <String>[],
  });

  final bool success;
  final String message;
  final String? token;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<String> permissions;
}
