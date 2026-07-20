import '../../features/posts/domain/entities/post_entity.dart';
import '../../domain/publish_target.dart';
import '../core/auth_result.dart';
import '../core/platform_analytics.dart';
import '../core/platform_capability.dart';
import '../core/platform_error_mapping.dart';
import '../core/platform_sdk.dart';
import '../core/publish_result.dart';
import '../core/social_platform.dart';
import '../sdk/x_sdk/x_sdk.dart';

class XPlatform implements SocialPlatform {
  const XPlatform({this.sdk = const XSdk()});

  final XSdk sdk;

  @override
  String get platformId => 'twitter';

  @override
  Set<String> get supportedTargetKeys => const {'twitter', 'x'};

  @override
  Future<AuthResult> connect() async {
    return sdk.authenticate();
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<PublishResult> publish(PostEntity post) {
    return sdk.publish(post);
  }

  Future<String> uploadMedia({
    required String postId,
    required String mediaUrl,
    required String mimeType,
  }) {
    return sdk.uploadMedia(
      UploadMediaRequest(
        postId: postId,
        mediaUrl: mediaUrl,
        mimeType: mimeType,
      ),
    );
  }

  Future<void> deletePost(String externalPostId) {
    return sdk.delete(externalPostId);
  }

  Future<PlatformAnalytics> fetchAnalytics(String externalPostId) {
    return sdk.analytics(externalPostId);
  }

  PlatformErrorMapping mapError(Object error, [StackTrace? stackTrace]) {
    return sdk.mapError(error, stackTrace);
  }

  @override
  bool supportsTarget(PublishTarget target) {
    return supportedTargetKeys.contains(target.destinationKey);
  }

  @override
  Future<bool> validate() async {
    return true;
  }

  @override
  PlatformCapability capability() {
    return const PlatformCapability(
      maxImages: 4,
      maxVideos: 1,
      supportsScheduling: true,
      supportsHashtags: true,
      supportsMentions: true,
      maxCaptionLength: 280,
      maxVideoSize: 512000000,
      maxImageSize: 5000000,
    );
  }
}
