enum ApiVersion { v1 }

final class LaravelApi {
  LaravelApi._();

  static const String apiBaseUrl = String.fromEnvironment(
    'SP_API_BASE_URL',
    defaultValue: 'https://api.smartpublisher.local',
  );

  static const String authBaseUrl = String.fromEnvironment(
    'SP_AUTH_BASE_URL',
    defaultValue: apiBaseUrl,
  );

  static const String openApiUrl = String.fromEnvironment(
    'SP_OPENAPI_URL',
    defaultValue: 'https://api.smartpublisher.local/api/v1/openapi.json',
  );

  static const String _apiPrefix = '/api';

  static String versionPrefix([ApiVersion version = ApiVersion.v1]) {
    switch (version) {
      case ApiVersion.v1:
        return '$_apiPrefix/v1';
    }
  }

  static String versioned(String path, [ApiVersion version = ApiVersion.v1]) {
    if (path.isEmpty) {
      return versionPrefix(version);
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

  static final String mediaUpload = LaravelApi.versioned('/media/upload');
  static final String mediaCompress = LaravelApi.versioned('/media/compress');
  static String mediaById(String id) => LaravelApi.versioned('/media/$id');

  static final String publishJobs = LaravelApi.versioned('/publish/jobs');
  static String publishJobById(String id) =>
      LaravelApi.versioned('/publish/jobs/$id');

  static final String accounts = LaravelApi.versioned('/accounts');
  static final String accountsConnect = LaravelApi.versioned(
    '/accounts/connect',
  );
  static String accountById(String id) => LaravelApi.versioned('/accounts/$id');

  static final String authRefresh = LaravelApi.versioned('/auth/refresh');
  static final String authLogin = LaravelApi.versioned('/auth/login');

  static final String analyticsDashboard = LaravelApi.versioned(
    '/analytics/dashboard',
  );
  static String analyticsPostById(String postId) =>
      LaravelApi.versioned('/analytics/posts/$postId');

  static final String notifications = LaravelApi.versioned('/notifications');
  static String notificationById(String id) =>
      LaravelApi.versioned('/notifications/$id');
}
