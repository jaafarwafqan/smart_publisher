import '../../../../core/result/app_result.dart';
import '../entities/oauth_provider_setting_entity.dart';

abstract class SystemSettingsRepository {
  const SystemSettingsRepository();

  Future<AppResult<List<OAuthProviderSettingEntity>>>
  getOAuthProviderSettings();

  Future<AppResult<OAuthProviderSettingEntity>> updateOAuthProviderSetting(
    String provider, {
    String? clientId,
    String? clientSecret,
    String? authorizeUrl,
    String? tokenUrl,
    List<String>? defaultScopes,
    bool? isEnabled,
  });

  Future<AppResult<ConnectionTestResultEntity>> testConnection(String provider);

  Future<AppResult<List<OAuthProviderAuditLogEntryEntity>>> getAuditLog(
    String provider,
  );
}
