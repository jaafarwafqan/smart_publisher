import '../../../features/posts/domain/entities/post_entity.dart';
import '../../core/auth_result.dart';
import '../../core/platform_analytics.dart';
import '../../core/platform_error_mapping.dart';
import '../../core/platform_exception.dart';
import '../../core/platform_sdk.dart';
import '../../core/publish_result.dart';

class TelegramSdk implements PlatformSdk {
  const TelegramSdk();

  @override
  Future<AuthResult> authenticate() async {
    final now = DateTime.now().toUtc();
    return AuthResult(
      success: true,
      message: 'Telegram authenticated',
      token: 'tg_bot_${now.microsecondsSinceEpoch}',
      refreshToken: null,
      expiresAt: null,
      permissions: const <String>['bot:send_message', 'bot:send_media'],
    );
  }

  @override
  Future<PublishResult> publish(PostEntity post) async {
    if (post.title.isEmpty || post.body.isEmpty) {
      throw const PlatformException(
        'Post title and body are required.',
        code: 'TG001',
      );
    }

    return PublishResult(
      success: true,
      message: 'Telegram post published',
      externalId: 'telegram-${post.id}',
    );
  }

  @override
  Future<String> uploadMedia(UploadMediaRequest request) async {
    if (request.mediaUrl.isEmpty) {
      throw const PlatformException('Media URL is required.', code: 'TG002');
    }
    return 'telegram-media-${request.postId}';
  }

  @override
  Future<void> delete(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'TG003',
      );
    }
  }

  @override
  Future<PlatformAnalytics> analytics(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'TG004',
      );
    }

    return PlatformAnalytics(
      platform: 'telegram',
      externalPostId: externalPostId,
      metrics: const <String, num>{'views': 0, 'reactions': 0},
    );
  }

  @override
  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    if (error is PlatformException) {
      final code = error.code ?? 'TG000';
      if (code == 'TG001' || code == 'TG002') {
        return PlatformErrorMapping(
          type: PlatformErrorType.validation,
          code: code,
          message: error.message,
        );
      }
      if (code == 'TG004') {
        return PlatformErrorMapping(
          type: PlatformErrorType.notFound,
          code: code,
          message: error.message,
        );
      }
    }

    return const PlatformErrorMapping(
      type: PlatformErrorType.unknown,
      code: 'TG999',
      message: 'Telegram SDK unknown error',
      retriable: false,
    );
  }
}
