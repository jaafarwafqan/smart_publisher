import '../../../features/posts/domain/entities/post_entity.dart';
import '../../core/auth_result.dart';
import '../../core/platform_analytics.dart';
import '../../core/platform_error_mapping.dart';
import '../../core/platform_exception.dart';
import '../../core/platform_sdk.dart';
import '../../core/publish_result.dart';

class InstagramSdk implements PlatformSdk {
  const InstagramSdk();

  @override
  Future<AuthResult> authenticate() async {
    final now = DateTime.now().toUtc();
    return AuthResult(
      success: true,
      message: 'Instagram authenticated',
      token: 'ig_access_${now.microsecondsSinceEpoch}',
      refreshToken: 'ig_refresh_${now.microsecondsSinceEpoch}',
      expiresAt: now.add(const Duration(days: 60)),
      permissions: const <String>[
        'instagram_basic',
        'instagram_content_publish',
        'pages_read_engagement',
      ],
    );
  }

  @override
  Future<PublishResult> publish(PostEntity post) async {
    if (post.body.isEmpty) {
      throw const PlatformException('Post body is required.', code: 'IG001');
    }

    return PublishResult(
      success: true,
      message: 'Instagram post published',
      externalId: 'instagram-${post.id}',
    );
  }

  @override
  Future<String> uploadMedia(UploadMediaRequest request) async {
    if (request.mediaUrl.isEmpty) {
      throw const PlatformException('Media URL is required.', code: 'IG002');
    }
    return 'instagram-media-${request.postId}';
  }

  @override
  Future<void> delete(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'IG003',
      );
    }
  }

  @override
  Future<PlatformAnalytics> analytics(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'IG004',
      );
    }

    return PlatformAnalytics(
      platform: 'instagram',
      externalPostId: externalPostId,
      metrics: const <String, num>{'impressions': 0, 'engagements': 0},
    );
  }

  @override
  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    if (error is PlatformException) {
      final code = error.code ?? 'IG000';
      if (code == 'IG001' || code == 'IG002') {
        return PlatformErrorMapping(
          type: PlatformErrorType.validation,
          code: code,
          message: error.message,
        );
      }
      if (code == 'IG004') {
        return PlatformErrorMapping(
          type: PlatformErrorType.notFound,
          code: code,
          message: error.message,
        );
      }
    }

    return const PlatformErrorMapping(
      type: PlatformErrorType.unknown,
      code: 'IG999',
      message: 'Instagram SDK unknown error',
      retriable: false,
    );
  }
}
