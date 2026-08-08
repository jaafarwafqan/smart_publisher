import 'package:flutter/foundation.dart';

enum ApiVersion { v1 }

final class LaravelApi {
  LaravelApi._();

  static const String apiBaseUrl = String.fromEnvironment(
    'SP_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  static const String authBaseUrl = String.fromEnvironment(
    'SP_AUTH_BASE_URL',
    defaultValue: apiBaseUrl,
  );

  static const String oauthBaseUrl = String.fromEnvironment(
    'SP_OAUTH_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String openApiUrl = String.fromEnvironment(
    'SP_OPENAPI_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1/openapi.json',
  );

  static const String _versionPrefix = '';

  /// A release build must never fall back to the localhost HTTP defaults used
  /// for developer tooling. The pipeline supplies all three values via
  /// `--dart-define`; this runtime guard protects a manually built AAB too.
  static void assertReleaseConfiguration() {
    if (!kReleaseMode) {
      return;
    }

    if (!hasSecureReleaseEndpoints(
      api: apiBaseUrl,
      auth: authBaseUrl,
      oauth: oauthBaseUrl,
    )) {
      throw StateError(
        'Release builds require HTTPS SP_API_BASE_URL, SP_AUTH_BASE_URL, and '
        'SP_OAUTH_BASE_URL dart-defines.',
      );
    }
  }

  static bool hasSecureReleaseEndpoints({
    required String api,
    required String auth,
    required String oauth,
  }) {
    return isSecureProductionEndpoint(api) &&
        isSecureProductionEndpoint(auth) &&
        isSecureProductionEndpoint(oauth);
  }

  static bool isSecureProductionEndpoint(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static String apiPath(String path) {
    if (path.isEmpty) {
      return '/';
    }
    if (!path.startsWith('/')) {
      return '/$path';
    }
    return path;
  }

  static String versionPrefix([ApiVersion version = ApiVersion.v1]) {
    switch (version) {
      case ApiVersion.v1:
        return _versionPrefix;
    }
  }

  static String versioned(String path, [ApiVersion version = ApiVersion.v1]) {
    if (path.isEmpty) {
      return versionPrefix(version);
    }
    if (versionPrefix(version).isEmpty) {
      return apiPath(path);
    }
    if (!path.startsWith('/')) {
      return '${versionPrefix(version)}/$path';
    }
    return '${versionPrefix(version)}$path';
  }

  static String acceptHeader([ApiVersion version = ApiVersion.v1]) {
    switch (version) {
      case ApiVersion.v1:
        return 'application/vnd.smartpublisher.v1+json';
    }
  }

  static String apiVersionHeaderValue([ApiVersion version = ApiVersion.v1]) {
    switch (version) {
      case ApiVersion.v1:
        return 'v1';
    }
  }
}

final class LaravelEndpoints {
  LaravelEndpoints._();

  static final String posts = LaravelApi.versioned('/posts');
  static String postById(String id) => LaravelApi.versioned('/posts/$id');

  static final String mediaUpload = LaravelApi.versioned('/media');
  static String mediaCompress(String id) =>
      LaravelApi.versioned('/media/$id/compress');
  static String mediaById(String id) => LaravelApi.versioned('/media/$id');
  static String postMediaAttach(String postId) =>
      LaravelApi.versioned('/posts/$postId/media/attach');

  // Sprint 2 (API Hardening, backend): the legacy /accounts/* endpoints
  // these three constants pointed at were removed server-side — only
  // index() was ever implemented there; connect/show/update/destroy 500'd
  // on every call. AccountRepositoryImpl was migrated onto
  // socialAccountsList/socialAccountsStore/etc. below in an earlier
  // session, and grep confirmed zero remaining references to these three.

  static String socialAccountsList(String userId) =>
      LaravelApi.versioned('/users/$userId/social-accounts');
  static String socialAccountsStore(String userId) =>
      LaravelApi.versioned('/users/$userId/social-accounts');
  static String socialAccountById(String userId, String socialAccountId) =>
      LaravelApi.versioned('/users/$userId/social-accounts/$socialAccountId');
  static String socialAccountRefreshToken(
    String userId,
    String socialAccountId,
  ) => LaravelApi.versioned(
    '/users/$userId/social-accounts/$socialAccountId/refresh-token',
  );
  static String socialAccountTestConnection(
    String userId,
    String socialAccountId,
  ) => LaravelApi.versioned(
    '/users/$userId/social-accounts/$socialAccountId/test',
  );

  static String telegramConnect(String userId) =>
      LaravelApi.versioned('/users/$userId/social-accounts/telegram/connect');
  static String socialAccountsAuthorize(String userId) =>
      LaravelApi.versioned('/users/$userId/social-accounts/authorize');
  static String socialAccountsCallback(String userId) =>
      LaravelApi.versioned('/users/$userId/social-accounts/callback');
  static String socialPages(String userId, String socialAccountId) =>
      LaravelApi.versioned(
        '/users/$userId/social-accounts/$socialAccountId/pages',
      );
  static String socialPagesSync(String userId, String socialAccountId) =>
      '${socialPages(userId, socialAccountId)}/sync';
  static String socialPagesAdd(String userId, String socialAccountId) =>
      '${socialPages(userId, socialAccountId)}/add';
  static String socialPagesSelect(String userId, String socialAccountId) =>
      '${socialPages(userId, socialAccountId)}/select';
  static String socialPageById(
    String userId,
    String socialAccountId,
    String pageId,
  ) => '${socialPages(userId, socialAccountId)}/$pageId';

  static String postPublishNow(String postId) =>
      LaravelApi.versioned('/posts/$postId/publish-now');
  static String postSchedule(String postId) =>
      LaravelApi.versioned('/posts/$postId/schedule');
  static String postDraft(String postId) =>
      LaravelApi.versioned('/posts/$postId/draft');

  static final String calendar = LaravelApi.versioned('/calendar');

  static final String organizations = LaravelApi.versioned('/organizations');
  static String organizationSwitch(String organizationId) =>
      LaravelApi.versioned('/organizations/$organizationId/switch');

  static final String organizationMembers = LaravelApi.versioned(
    '/organization/members',
  );
  static String organizationMemberById(String userId) =>
      LaravelApi.versioned('/organization/members/$userId');

  static final String systemSettingsOAuthProviders = LaravelApi.versioned(
    '/system-settings/oauth-providers',
  );
  static String systemSettingsOAuthProviderById(String provider) =>
      LaravelApi.versioned('/system-settings/oauth-providers/$provider');
  static String systemSettingsOAuthProviderTest(String provider) =>
      LaravelApi.versioned('/system-settings/oauth-providers/$provider/test');
  static String systemSettingsOAuthProviderAuditLog(String provider) =>
      LaravelApi.versioned(
        '/system-settings/oauth-providers/$provider/audit-log',
      );

  static final List<String> authLoginCandidates = <String>[
    LaravelApi.apiPath('/auth/login'),
  ];
  static final List<String> authRefreshCandidates = <String>[
    LaravelApi.apiPath('/auth/refresh'),
  ];
  static final String authLogin = authLoginCandidates.first;
  static final String authRefresh = authRefreshCandidates.first;
  static final String authLogout = LaravelApi.apiPath('/auth/logout');
  static final String me = LaravelApi.versioned('/me');

  // Sprint 4 (Commercial SaaS): registration, password reset, email
  // verification resend, and TOTP-based MFA — all under /auth like the
  // pre-auth endpoints above.
  static final String authRegister = LaravelApi.apiPath('/auth/register');
  static final String authForgotPassword = LaravelApi.apiPath(
    '/auth/forgot-password',
  );
  static final String authResetPassword = LaravelApi.apiPath(
    '/auth/reset-password',
  );
  static final String authEmailVerificationResend = LaravelApi.apiPath(
    '/auth/email/verification-notification',
  );
  static final String authTwoFactorEnable = LaravelApi.apiPath(
    '/auth/two-factor/enable',
  );
  static final String authTwoFactorConfirm = LaravelApi.apiPath(
    '/auth/two-factor/confirm',
  );
  static final String authTwoFactorDisable = LaravelApi.apiPath(
    '/auth/two-factor/disable',
  );
  static final String authTwoFactorChallenge = LaravelApi.apiPath(
    '/auth/two-factor/challenge',
  );

  static final String analyticsDashboard = LaravelApi.versioned(
    '/analytics/dashboard',
  );
  static final String analyticsSummary = LaravelApi.versioned('/analytics');
  static String analyticsPostById(String postId) =>
      LaravelApi.versioned('/analytics/posts/$postId');
  static String analyticsPostsBulk(List<String> postIds) {
    final query = postIds
        .map((id) => 'post_ids[]=${Uri.encodeQueryComponent(id)}')
        .join('&');
    return '${LaravelApi.versioned('/analytics/posts')}?$query';
  }

  static final String notifications = LaravelApi.versioned('/notifications');
  static String notificationById(String id) =>
      LaravelApi.versioned('/notifications/$id');
}
