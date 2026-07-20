import '../../../features/posts/domain/entities/post_entity.dart';
import '../../core/auth_result.dart';
import '../../core/platform_analytics.dart';
import '../../core/platform_error_mapping.dart';
import '../../core/platform_exception.dart';
import '../../core/platform_sdk.dart';
import '../../core/publish_result.dart';

class TikTokSdk implements PlatformSdk {
  const TikTokSdk();

  @override
  Future<AuthResult> authenticate() async {
    throw const PlatformException(
      'TikTok integration is not enabled yet.',
      code: 'TK000',
    );
  }

  @override
  Future<PublishResult> publish(PostEntity post) async {
    throw const PlatformException(
      'TikTok publishing is planned for a future phase.',
      code: 'TK001',
    );
  }

  @override
  Future<String> uploadMedia(UploadMediaRequest request) async {
    throw const PlatformException(
      'TikTok media upload is planned for a future phase.',
      code: 'TK002',
    );
  }

  @override
  Future<void> delete(String externalPostId) async {
    throw const PlatformException(
      'TikTok delete is planned for a future phase.',
      code: 'TK003',
    );
  }

  @override
  Future<PlatformAnalytics> analytics(String externalPostId) async {
    throw const PlatformException(
      'TikTok analytics is planned for a future phase.',
      code: 'TK004',
    );
  }

  @override
  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    if (error is PlatformException) {
      return PlatformErrorMapping(
        type: PlatformErrorType.unavailable,
        code: error.code ?? 'TK000',
        message: error.message,
        retriable: false,
      );
    }

    return const PlatformErrorMapping(
      type: PlatformErrorType.unknown,
      code: 'TK999',
      message: 'TikTok SDK unknown error',
      retriable: false,
    );
  }
}
