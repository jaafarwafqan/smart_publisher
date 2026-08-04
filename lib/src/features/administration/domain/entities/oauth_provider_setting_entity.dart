class OAuthProviderSettingEntity {
  const OAuthProviderSettingEntity({
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

  bool get isConfigured => (clientId?.isNotEmpty ?? false) && hasClientSecret;
}

class ConnectionTestResultEntity {
  const ConnectionTestResultEntity({
    required this.success,
    required this.message,
    this.testedAt,
  });

  final bool success;
  final String message;
  final DateTime? testedAt;
}

class OAuthProviderAuditLogEntryEntity {
  const OAuthProviderAuditLogEntryEntity({
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
}
