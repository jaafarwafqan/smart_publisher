import '../../features/posts/domain/entities/post_entity.dart';
import 'auth_result.dart';
import 'platform_analytics.dart';
import 'platform_error_mapping.dart';
import 'publish_result.dart';

class UploadMediaRequest {
  const UploadMediaRequest({
    required this.postId,
    required this.mediaUrl,
    required this.mimeType,
  });

  final String postId;
  final String mediaUrl;
  final String mimeType;
}

abstract interface class PlatformSdk {
  Future<AuthResult> authenticate();

  Future<PublishResult> publish(PostEntity post);

  Future<String> uploadMedia(UploadMediaRequest request);

  Future<void> delete(String externalPostId);

  Future<PlatformAnalytics> analytics(String externalPostId);

  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]);
}
