class AuthResult {
  const AuthResult({required this.success, required this.message, this.token});

  final bool success;
  final String message;
  final String? token;
}
