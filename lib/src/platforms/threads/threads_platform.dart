import '../../features/posts/domain/entities/post_entity.dart';
import '../../domain/publish_target.dart';
import '../core/auth_result.dart';
import '../core/platform_capability.dart';
import '../core/platform_exception.dart';
import '../core/publish_result.dart';
import '../core/social_platform.dart';

class ThreadsPlatform implements SocialPlatform {
  const ThreadsPlatform();

  @override
  String get platformId => 'threads';

  @override
  Set<String> get supportedTargetKeys => const {'threads'};

  @override
  Future<AuthResult> connect() async {
    return const AuthResult(success: true, message: 'Threads connected');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<PublishResult> publish(PostEntity post) async {
    if (post.body.isEmpty) {
      throw const PlatformException('Post body is required.', code: 'TH001');
    }

    return PublishResult(
      success: true,
      message: 'Threads post published',
      externalId: 'threads-${post.id}',
    );
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
      maxImages: 10,
      maxVideos: 1,
      supportsScheduling: true,
      supportsHashtags: true,
      supportsMentions: true,
      maxCaptionLength: 500,
      maxVideoSize: 1000000000,
      maxImageSize: 8000000,
    );
  }
}
