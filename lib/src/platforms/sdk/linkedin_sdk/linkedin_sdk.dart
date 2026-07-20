import '../../../features/posts/domain/entities/post_entity.dart';
import '../../core/auth_result.dart';
import '../../core/platform_analytics.dart';
import '../../core/platform_error_mapping.dart';
import '../../core/platform_exception.dart';
import '../../core/platform_sdk.dart';
import '../../core/publish_result.dart';

class LinkedInSdk implements PlatformSdk {
  const LinkedInSdk();

  @override
  Future<AuthResult> authenticate() async {
    final now = DateTime.now().toUtc();
    return AuthResult(
      success: true,
      message: 'LinkedIn authenticated',
      token: 'li_access_${now.microsecondsSinceEpoch}',
      refreshToken: 'li_refresh_${now.microsecondsSinceEpoch}',
      expiresAt: now.add(const Duration(days: 60)),
      permissions: const <String>['w_member_social', 'r_organization_social'],
    );
  }

  @override
  Future<PublishResult> publish(PostEntity post) async {
    if (post.body.isEmpty) {
      throw const PlatformException('Post body is required.', code: 'LI001');
    }

    return PublishResult(
      success: true,
      message: 'LinkedIn post published',
      externalId: 'linkedin-${post.id}',
    );
  }

  @override
  Future<String> uploadMedia(UploadMediaRequest request) async {
    if (request.mediaUrl.isEmpty) {
      throw const PlatformException('Media URL is required.', code: 'LI002');
    }
    return 'linkedin-media-${request.postId}';
  }

  @override
  Future<void> delete(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'LI003',
      );
    }
  }

  @override
  Future<PlatformAnalytics> analytics(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'LI004',
      );
    }

    return PlatformAnalytics(
      platform: 'linkedin',
      externalPostId: externalPostId,
      metrics: const <String, num>{
        'impressions': 0,
        'clicks': 0,
        'engagements': 0,
      },
    );
  }

  @override
  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    if (error is PlatformException) {
      final code = error.code ?? 'LI000';
      if (code == 'LI001' || code == 'LI002') {
        return PlatformErrorMapping(
          type: PlatformErrorType.validation,
          code: code,
          message: error.message,
        );
      }
      if (code == 'LI004') {
        return PlatformErrorMapping(
          type: PlatformErrorType.notFound,
          code: code,
          message: error.message,
        );
      }
    }

    return const PlatformErrorMapping(
      type: PlatformErrorType.unknown,
      code: 'LI999',
      message: 'LinkedIn SDK unknown error',
      retriable: false,
    );
  }
}
