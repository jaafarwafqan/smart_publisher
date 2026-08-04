class SocialAccountResponseDtoV1 {
  const SocialAccountResponseDtoV1({
    required this.id,
    required this.provider,
    required this.providerAccountId,
    this.accountName,
    this.accountUsername,
    this.tokenExpiresAt,
    this.isTokenExpired = false,
    this.hasRefreshToken = false,
    this.scopes = const <String>[],
    required this.status,
    this.isActive = true,
    this.discoveryMode = 'manual',
    this.metadata = const <String, dynamic>{},
    this.lastSyncedAt,
    this.lastPublishedAt,
  });

  final String id;
  final String provider;
  final String providerAccountId;
  final String? accountName;
  final String? accountUsername;
  final DateTime? tokenExpiresAt;
  final bool isTokenExpired;
  final bool hasRefreshToken;
  final List<String> scopes;
  final String status;
  final bool isActive;
  final String discoveryMode;
  final Map<String, dynamic> metadata;
  final DateTime? lastSyncedAt;
  final DateTime? lastPublishedAt;

  factory SocialAccountResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return SocialAccountResponseDtoV1(
      id: (json['id'] ?? '').toString(),
      provider: (json['provider'] ?? '') as String,
      providerAccountId: (json['provider_account_id'] ?? '') as String,
      accountName: json['account_name'] as String?,
      accountUsername: json['account_username'] as String?,
      tokenExpiresAt: json['token_expires_at'] == null
          ? null
          : DateTime.tryParse(json['token_expires_at'].toString()),
      isTokenExpired: (json['is_token_expired'] ?? false) as bool,
      hasRefreshToken: (json['has_refresh_token'] ?? false) as bool,
      scopes: (json['scopes'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      status: (json['status'] ?? 'pending') as String,
      isActive: (json['is_active'] ?? true) as bool,
      discoveryMode: (json['discovery_mode'] ?? 'manual') as String,
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
      lastSyncedAt: json['last_synced_at'] == null
          ? null
          : DateTime.tryParse(json['last_synced_at'].toString()),
      lastPublishedAt: json['last_published_at'] == null
          ? null
          : DateTime.tryParse(json['last_published_at'].toString()),
    );
  }
}

class BeginOAuthAuthorizationRequestDtoV1 {
  const BeginOAuthAuthorizationRequestDtoV1({
    required this.provider,
    required this.redirectUri,
    this.scopes = const <String>[],
  });

  final String provider;
  final String redirectUri;
  final List<String> scopes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provider': provider,
      'redirect_uri': redirectUri,
      'scopes': scopes,
    };
  }
}

class BeginOAuthAuthorizationResponseDtoV1 {
  const BeginOAuthAuthorizationResponseDtoV1({
    required this.provider,
    required this.state,
    this.stateExpiresAt,
    required this.authorizeUrl,
  });

  final String provider;
  final String state;
  final DateTime? stateExpiresAt;
  final String authorizeUrl;

  factory BeginOAuthAuthorizationResponseDtoV1.fromJson(
    Map<String, dynamic> json,
  ) {
    return BeginOAuthAuthorizationResponseDtoV1(
      provider: (json['provider'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      stateExpiresAt: json['state_expires_at'] == null
          ? null
          : DateTime.tryParse(json['state_expires_at'].toString()),
      authorizeUrl: (json['authorize_url'] ?? '').toString(),
    );
  }
}

class OAuthCallbackRequestDtoV1 {
  const OAuthCallbackRequestDtoV1({
    required this.provider,
    required this.code,
    required this.state,
    this.scopes = const <String>[],
  });

  final String provider;
  final String code;
  final String state;
  final List<String> scopes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provider': provider,
      'code': code,
      'state': state,
      'scopes': scopes,
    };
  }
}

class ConnectSocialAccountRequestDtoV1 {
  const ConnectSocialAccountRequestDtoV1({
    required this.provider,
    required this.providerAccountId,
    this.accountName,
    this.accountUsername,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiresAt,
    this.scopes = const <String>[],
  });

  final String provider;
  final String providerAccountId;
  final String? accountName;
  final String? accountUsername;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? tokenExpiresAt;
  final List<String> scopes;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'provider': provider,
      'provider_account_id': providerAccountId,
      'account_name': accountName,
      'account_username': accountUsername,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_expires_at': tokenExpiresAt?.toIso8601String(),
      'scopes': scopes,
    };
  }
}
