import '../../../features/posts/domain/entities/post_entity.dart';
import '../../core/auth_result.dart';
import '../../core/platform_analytics.dart';
import '../../core/platform_error_mapping.dart';
import '../../core/platform_exception.dart';
import '../../core/platform_sdk.dart';
import '../../core/publish_result.dart';

class FacebookSdk implements PlatformSdk {
  const FacebookSdk();

  @override
  Future<AuthResult> authenticate() async {
    final now = DateTime.now().toUtc();
    return AuthResult(
      success: true,
      message: 'Facebook authenticated',
      token: 'fb_access_${now.microsecondsSinceEpoch}',
      refreshToken: 'fb_refresh_${now.microsecondsSinceEpoch}',
      expiresAt: now.add(const Duration(days: 60)),
      permissions: const <String>[
        'pages_show_list',
        'pages_read_engagement',
        'pages_manage_posts',
      ],
    );
  }

  @override
  Future<PublishResult> publish(PostEntity post) async {
    if (post.title.isEmpty || post.body.isEmpty) {
      throw const PlatformException(
        'Post title and body are required.',
        code: 'FB001',
      );
    }

    return PublishResult(
      success: true,
      message: 'Facebook post published',
      externalId: 'facebook-${post.id}',
    );
  }

  @override
  Future<String> uploadMedia(UploadMediaRequest request) async {
    if (request.mediaUrl.isEmpty) {
      throw const PlatformException('Media URL is required.', code: 'FB002');
    }
    return 'facebook-media-${request.postId}';
  }

  @override
  Future<void> delete(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'FB003',
      );
    }
  }

  @override
  Future<PlatformAnalytics> analytics(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'FB004',
      );
    }

    return PlatformAnalytics(
      platform: 'facebook',
      externalPostId: externalPostId,
      metrics: const <String, num>{'impressions': 0, 'engagements': 0},
    );
  }

  @override
  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    if (error is PlatformException) {
      final code = error.code ?? 'FB000';
      if (code == 'FB001' || code == 'FB002') {
        return PlatformErrorMapping(
          type: PlatformErrorType.validation,
          code: code,
          message: error.message,
        );
      }
      if (code == 'FB004') {
        return PlatformErrorMapping(
          type: PlatformErrorType.notFound,
          code: code,
          message: error.message,
        );
      }
    }

    return const PlatformErrorMapping(
      type: PlatformErrorType.unknown,
      code: 'FB999',
      message: 'Facebook SDK unknown error',
      retriable: false,
    );
  }
}
