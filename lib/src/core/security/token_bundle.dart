class TokenBundle {
  const TokenBundle({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.scopes = const <String>{},
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final Set<String> scopes;
  final String tokenType;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool willExpireWithin(Duration window) {
    return DateTime.now().add(window).isAfter(expiresAt);
  }
}
