import '../../domain/publish_target.dart';
import '../../features/posts/domain/entities/post_entity.dart';
import '../core/auth_result.dart';
import '../core/platform_analytics.dart';
import '../core/platform_capability.dart';
import '../core/platform_error_mapping.dart';
import '../core/platform_sdk.dart';
import '../core/publish_result.dart';
import '../core/social_platform.dart';
import '../sdk/tiktok_sdk/tiktok_sdk.dart';

class TikTokPlatform implements SocialPlatform {
  const TikTokPlatform({this.sdk = const TikTokSdk()});

  final TikTokSdk sdk;

  @override
  String get platformId => 'tiktok';

  @override
  Set<String> get supportedTargetKeys => const {'tiktok'};

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
    return false;
  }

  @override
  PlatformCapability capability() {
    return const PlatformCapability(
      maxImages: 35,
      maxVideos: 1,
      supportsScheduling: false,
      supportsHashtags: true,
      supportsMentions: true,
      maxCaptionLength: 2200,
      maxVideoSize: 4000000000,
      maxImageSize: 20000000,
    );
  }
}
