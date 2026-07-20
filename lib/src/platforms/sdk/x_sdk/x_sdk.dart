import '../../../features/posts/domain/entities/post_entity.dart';
import '../../core/auth_result.dart';
import '../../core/platform_analytics.dart';
import '../../core/platform_error_mapping.dart';
import '../../core/platform_exception.dart';
import '../../core/platform_sdk.dart';
import '../../core/publish_result.dart';

class XSdk implements PlatformSdk {
  const XSdk();

  @override
  Future<AuthResult> authenticate() async {
    final now = DateTime.now().toUtc();
    return AuthResult(
      success: true,
      message: 'X authenticated',
      token: 'x_access_${now.microsecondsSinceEpoch}',
      refreshToken: 'x_refresh_${now.microsecondsSinceEpoch}',
      expiresAt: now.add(const Duration(days: 30)),
      permissions: const <String>['tweet.read', 'tweet.write', 'users.read'],
    );
  }

  @override
  Future<PublishResult> publish(PostEntity post) async {
    if (post.body.isEmpty) {
      throw const PlatformException('Post body is required.', code: 'X001');
    }

    return PublishResult(
      success: true,
      message: 'X post published',
      externalId: 'x-${post.id}',
    );
  }

  @override
  Future<String> uploadMedia(UploadMediaRequest request) async {
    if (request.mediaUrl.isEmpty) {
      throw const PlatformException('Media URL is required.', code: 'X002');
    }
    return 'x-media-${request.postId}';
  }

  @override
  Future<void> delete(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'X003',
      );
    }
  }

  @override
  Future<PlatformAnalytics> analytics(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'X004',
      );
    }

    return PlatformAnalytics(
      platform: 'x',
      externalPostId: externalPostId,
      metrics: const <String, num>{'impressions': 0, 'likes': 0, 'retweets': 0},
    );
  }

  @override
  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    if (error is PlatformException) {
      final code = error.code ?? 'X000';
      if (code == 'X001' || code == 'X002') {
        return PlatformErrorMapping(
          type: PlatformErrorType.validation,
          code: code,
          message: error.message,
        );
      }
      if (code == 'X004') {
        return PlatformErrorMapping(
          type: PlatformErrorType.notFound,
          code: code,
          message: error.message,
        );
      }
    }

    return const PlatformErrorMapping(
      type: PlatformErrorType.unknown,
      code: 'X999',
      message: 'X SDK unknown error',
      retriable: false,
    );
  }
}
