/// Sprint 4 (Commercial SaaS): the "download my data" / "delete my
/// account" contracts — GET /account/data-export and
/// POST /account/data-deletion-requests. Both are personal-account
/// endpoints (not organization-scoped), matching
/// AccountDataExportController / AccountDataDeletionController.
class DataExportDtoV1 {
  const DataExportDtoV1({
    required this.userName,
    required this.userEmail,
    required this.twoFactorEnabled,
    required this.emailVerifiedAt,
    required this.organizationsCount,
    required this.postsCount,
    required this.socialAccountsCount,
    required this.mediaAttachmentsCount,
    required this.exportedAt,
    required this.rawJson,
  });

  final String userName;
  final String userEmail;
  final bool twoFactorEnabled;
  final String? emailVerifiedAt;
  final int organizationsCount;
  final int postsCount;
  final int socialAccountsCount;
  final int mediaAttachmentsCount;
  final String exportedAt;

  /// The full, unmodified response — used for the "copy as JSON" action so
  /// nothing the backend returned is silently dropped from what the user
  /// can actually save.
  final Map<String, dynamic> rawJson;

  factory DataExportDtoV1.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : const <String, dynamic>{};

    List<dynamic> listOf(String key) {
      final value = json[key];
      return value is List<dynamic> ? value : const <dynamic>[];
    }

    return DataExportDtoV1(
      userName: (user['name'] ?? '').toString(),
      userEmail: (user['email'] ?? '').toString(),
      twoFactorEnabled: user['two_factor_enabled'] == true,
      emailVerifiedAt: user['email_verified_at']?.toString(),
      organizationsCount: listOf('organizations').length,
      postsCount: listOf('posts').length,
      socialAccountsCount: listOf('social_accounts').length,
      mediaAttachmentsCount: listOf('media_attachments').length,
      exportedAt: (json['exported_at'] ?? '').toString(),
      rawJson: json,
    );
  }
}

class DataDeletionRequestDtoV1 {
  const DataDeletionRequestDtoV1({
    required this.id,
    required this.status,
    required this.requestedAt,
  });

  final String id;
  final String status;
  final String requestedAt;

  factory DataDeletionRequestDtoV1.fromJson(Map<String, dynamic> json) {
    return DataDeletionRequestDtoV1(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      requestedAt: (json['requested_at'] ?? '').toString(),
    );
  }
}
