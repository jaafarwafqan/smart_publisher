class AccountResponseDtoV1 {
  const AccountResponseDtoV1({
    required this.id,
    required this.name,
    required this.platform,
    required this.isConnected,
    this.avatarUrl,
    this.permissions = const <String>[],
  });

  final String id;
  final String name;
  final String platform;
  final bool isConnected;
  final String? avatarUrl;
  final List<String> permissions;

  factory AccountResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return AccountResponseDtoV1(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      platform: (json['platform'] ?? '') as String,
      isConnected: (json['is_connected'] ?? json['connected'] ?? false) as bool,
      avatarUrl: json['avatar_url'] as String?,
      permissions: (json['permissions'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}

class ConnectAccountRequestDtoV1 {
  const ConnectAccountRequestDtoV1({
    required this.platform,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.permissions = const <String>[],
  });

  final String platform;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final List<String> permissions;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'platform': platform,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt?.toIso8601String(),
      'permissions': permissions,
    };
  }
}
