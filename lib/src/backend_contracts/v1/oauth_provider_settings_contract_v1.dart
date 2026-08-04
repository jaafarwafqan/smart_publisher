class OAuthProviderSettingDtoV1 {
  const OAuthProviderSettingDtoV1({
    required this.provider,
    this.clientId,
    this.hasClientSecret = false,
    this.authorizeUrl,
    this.tokenUrl,
    this.defaultScopes = const <String>[],
    this.isMockIntegration = false,
    this.isEnabled = true,
    this.updatedAt,
    this.updatedByName,
    this.lastTestedAt,
    this.lastTestSuccess,
  });

  final String provider;
  final String? clientId;
  final bool hasClientSecret;
  final String? authorizeUrl;
  final String? tokenUrl;
  final List<String> defaultScopes;
  final bool isMockIntegration;
  final bool isEnabled;
  final DateTime? updatedAt;
  final String? updatedByName;
  final DateTime? lastTestedAt;
  final bool? lastTestSuccess;

  factory OAuthProviderSettingDtoV1.fromJson(Map<String, dynamic> json) {
    return OAuthProviderSettingDtoV1(
      provider: (json['provider'] ?? '').toString(),
      clientId: json['client_id'] as String?,
      hasClientSecret: (json['has_client_secret'] ?? false) as bool,
      authorizeUrl: json['authorize_url'] as String?,
      tokenUrl: json['token_url'] as String?,
      defaultScopes:
          (json['default_scopes'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
      isMockIntegration: (json['is_mock_integration'] ?? false) as bool,
      isEnabled: (json['is_enabled'] ?? true) as bool,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
      updatedByName: json['updated_by_name'] as String?,
      lastTestedAt: json['last_tested_at'] == null
          ? null
          : DateTime.tryParse(json['last_tested_at'].toString()),
      lastTestSuccess: json['last_test_success'] as bool?,
    );
  }
}

class ConnectionTestResultDtoV1 {
  const ConnectionTestResultDtoV1({
    required this.success,
    required this.message,
    this.testedAt,
  });

  final bool success;
  final String message;
  final DateTime? testedAt;

  factory ConnectionTestResultDtoV1.fromJson(Map<String, dynamic> json) {
    return ConnectionTestResultDtoV1(
      success: (json['success'] ?? false) as bool,
      message: (json['message'] ?? '').toString(),
      testedAt: json['tested_at'] == null
          ? null
          : DateTime.tryParse(json['tested_at'].toString()),
    );
  }
}

class OAuthProviderAuditLogEntryDtoV1 {
  const OAuthProviderAuditLogEntryDtoV1({
    required this.action,
    this.changedFields = const <String>[],
    this.success,
    this.userName,
    this.createdAt,
  });

  final String action;
  final List<String> changedFields;
  final bool? success;
  final String? userName;
  final DateTime? createdAt;

  factory OAuthProviderAuditLogEntryDtoV1.fromJson(Map<String, dynamic> json) {
    return OAuthProviderAuditLogEntryDtoV1(
      action: (json['action'] ?? '').toString(),
      changedFields:
          (json['changed_fields'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(growable: false),
      success: json['success'] as bool?,
      userName: json['user_name'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
    );
  }
}

class UpdateOAuthProviderSettingRequestDtoV1 {
  const UpdateOAuthProviderSettingRequestDtoV1({
    this.clientId,
    this.clientSecret,
    this.authorizeUrl,
    this.tokenUrl,
    this.defaultScopes,
    this.isEnabled,
  });

  final String? clientId;
  final String? clientSecret;
  final String? authorizeUrl;
  final String? tokenUrl;
  final List<String>? defaultScopes;
  final bool? isEnabled;

  /// Omits any field left unset entirely (never sends `null`) — leaving the
  /// client secret blank must mean "keep the current one", not "clear it",
  /// and the backend only preserves that when the key isn't present at all.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (clientId != null) json['client_id'] = clientId;
    if (clientSecret != null && clientSecret!.isNotEmpty) {
      json['client_secret'] = clientSecret;
    }
    if (authorizeUrl != null) json['authorize_url'] = authorizeUrl;
    if (tokenUrl != null) json['token_url'] = tokenUrl;
    if (defaultScopes != null) json['default_scopes'] = defaultScopes;
    if (isEnabled != null) json['is_enabled'] = isEnabled;
    return json;
  }
}
