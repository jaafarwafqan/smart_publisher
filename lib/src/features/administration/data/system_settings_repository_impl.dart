import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/oauth_provider_settings_contract_v1.dart';
import '../../../core/base/base_repository.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../domain/entities/oauth_provider_setting_entity.dart';
import '../domain/repositories/system_settings_repository.dart';

class SystemSettingsRepositoryImpl
    extends BaseRepository<OAuthProviderSettingEntity>
    implements SystemSettingsRepository {
  SystemSettingsRepositoryImpl({this.networkClient});

  final NetworkClient? networkClient;

  @override
  Future<AppResult<List<OAuthProviderSettingEntity>>>
  getOAuthProviderSettings() async {
    if (networkClient == null) {
      return Failure<List<OAuthProviderSettingEntity>>(
        'Loading system settings requires a connection.',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.get(
          LaravelEndpoints.systemSettingsOAuthProviders,
        );
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        return rawItems
            .whereType<Map<String, dynamic>>()
            .map((json) => _toEntity(OAuthProviderSettingDtoV1.fromJson(json)))
            .toList(growable: false);
      },
      operation: 'system_settings.oauth_providers.list',
      fallbackMessage: 'Failed to load system settings',
    );
  }

  @override
  Future<AppResult<OAuthProviderSettingEntity>> updateOAuthProviderSetting(
    String provider, {
    String? clientId,
    String? clientSecret,
    String? authorizeUrl,
    String? tokenUrl,
    List<String>? defaultScopes,
    bool? isEnabled,
  }) async {
    if (networkClient == null) {
      return Failure<OAuthProviderSettingEntity>(
        'Updating system settings requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.put(
          LaravelEndpoints.systemSettingsOAuthProviderById(provider),
          data: UpdateOAuthProviderSettingRequestDtoV1(
            clientId: clientId,
            clientSecret: clientSecret,
            authorizeUrl: authorizeUrl,
            tokenUrl: tokenUrl,
            defaultScopes: defaultScopes,
            isEnabled: isEnabled,
          ).toJson(),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid system settings update response.');
        }
        return _toEntity(OAuthProviderSettingDtoV1.fromJson(payload));
      },
      operation: 'system_settings.oauth_providers.update',
      fallbackMessage: 'Failed to update provider settings',
    );
  }

  @override
  Future<AppResult<ConnectionTestResultEntity>> testConnection(
    String provider,
  ) async {
    if (networkClient == null) {
      return Failure<ConnectionTestResultEntity>(
        'Testing the connection requires a connection.',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.post(
          LaravelEndpoints.systemSettingsOAuthProviderTest(provider),
        );
        final payload = _unwrapPayload(response.data);
        if (payload is! Map<String, dynamic>) {
          throw StateError('Invalid connection test response.');
        }
        final dto = ConnectionTestResultDtoV1.fromJson(payload);
        return ConnectionTestResultEntity(
          success: dto.success,
          message: dto.message,
          testedAt: dto.testedAt,
        );
      },
      operation: 'system_settings.oauth_providers.test_connection',
      fallbackMessage: 'Failed to test the connection',
    );
  }

  @override
  Future<AppResult<List<OAuthProviderAuditLogEntryEntity>>> getAuditLog(
    String provider,
  ) async {
    if (networkClient == null) {
      return Failure<List<OAuthProviderAuditLogEntryEntity>>(
        'Loading the audit log requires a connection.',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.get(
          LaravelEndpoints.systemSettingsOAuthProviderAuditLog(provider),
        );
        final payload = _unwrapPayload(response.data);
        final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
        return rawItems
            .whereType<Map<String, dynamic>>()
            .map((json) {
              final dto = OAuthProviderAuditLogEntryDtoV1.fromJson(json);
              return OAuthProviderAuditLogEntryEntity(
                action: dto.action,
                changedFields: dto.changedFields,
                success: dto.success,
                userName: dto.userName,
                createdAt: dto.createdAt,
              );
            })
            .toList(growable: false);
      },
      operation: 'system_settings.oauth_providers.audit_log',
      fallbackMessage: 'Failed to load the audit log',
    );
  }

  OAuthProviderSettingEntity _toEntity(OAuthProviderSettingDtoV1 dto) {
    return OAuthProviderSettingEntity(
      provider: dto.provider,
      clientId: dto.clientId,
      hasClientSecret: dto.hasClientSecret,
      authorizeUrl: dto.authorizeUrl,
      tokenUrl: dto.tokenUrl,
      defaultScopes: dto.defaultScopes,
      isMockIntegration: dto.isMockIntegration,
      isEnabled: dto.isEnabled,
      updatedAt: dto.updatedAt,
      updatedByName: dto.updatedByName,
      lastTestedAt: dto.lastTestedAt,
      lastTestSuccess: dto.lastTestSuccess,
    );
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }
}
