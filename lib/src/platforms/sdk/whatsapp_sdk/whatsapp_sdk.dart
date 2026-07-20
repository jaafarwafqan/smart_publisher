import '../../../features/posts/domain/entities/post_entity.dart';
import '../../core/auth_result.dart';
import '../../core/platform_analytics.dart';
import '../../core/platform_error_mapping.dart';
import '../../core/platform_exception.dart';
import '../../core/platform_sdk.dart';
import '../../core/publish_result.dart';

class WhatsAppSdk implements PlatformSdk {
  const WhatsAppSdk();

  @override
  Future<AuthResult> authenticate() async {
    final now = DateTime.now().toUtc();
    return AuthResult(
      success: true,
      message: 'WhatsApp authenticated',
      token: 'wa_access_${now.microsecondsSinceEpoch}',
      refreshToken: 'wa_refresh_${now.microsecondsSinceEpoch}',
      expiresAt: now.add(const Duration(days: 90)),
      permissions: const <String>['whatsapp_business_management'],
    );
  }

  @override
  Future<PublishResult> publish(PostEntity post) async {
    if (post.body.isEmpty) {
      throw const PlatformException('Post body is required.', code: 'WA001');
    }

    return PublishResult(
      success: true,
      message: 'WhatsApp message published',
      externalId: 'whatsapp-${post.id}',
    );
  }

  @override
  Future<String> uploadMedia(UploadMediaRequest request) async {
    if (request.mediaUrl.isEmpty) {
      throw const PlatformException('Media URL is required.', code: 'WA002');
    }
    return 'whatsapp-media-${request.postId}';
  }

  @override
  Future<void> delete(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'WA003',
      );
    }
  }

  @override
  Future<PlatformAnalytics> analytics(String externalPostId) async {
    if (externalPostId.isEmpty) {
      throw const PlatformException(
        'External post id is required.',
        code: 'WA004',
      );
    }

    return PlatformAnalytics(
      platform: 'whatsapp',
      externalPostId: externalPostId,
      metrics: const <String, num>{'delivered': 0, 'read': 0},
    );
  }

  @override
  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    if (error is PlatformException) {
      final code = error.code ?? 'WA000';
      if (code == 'WA001' || code == 'WA002') {
        return PlatformErrorMapping(
          type: PlatformErrorType.validation,
          code: code,
          message: error.message,
        );
      }
      if (code == 'WA004') {
        return PlatformErrorMapping(
          type: PlatformErrorType.notFound,
          code: code,
          message: error.message,
        );
      }
    }

    return const PlatformErrorMapping(
      type: PlatformErrorType.unknown,
      code: 'WA999',
      message: 'WhatsApp SDK unknown error',
      retriable: false,
    );
  }
}
