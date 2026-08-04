/// Result of testing whether a specific connection's stored access token
/// still works — distinct from System Settings' app-level Test Connection,
/// which only checks the Client ID/Secret pair, never a specific user's
/// token.
class AccountHealthCheckEntity {
  const AccountHealthCheckEntity({
    required this.available,
    required this.healthy,
    required this.message,
  });

  /// Whether live verification was actually attempted — false means the
  /// provider has no real check implemented yet, and [healthy] must not be
  /// read as "confirmed broken" in that case.
  final bool available;
  final bool healthy;
  final String message;
}
