import '../../features/posts/domain/entities/post_entity.dart';
import '../core/auth_result.dart';
import '../core/platform_capability.dart';
import '../core/platform_exception.dart';
import '../core/publish_result.dart';
import '../core/social_platform.dart';

class TelegramPlatform implements SocialPlatform {
  const TelegramPlatform();

  @override
  Future<AuthResult> connect() async {
    return const AuthResult(success: true, message: 'Telegram connected');
  }

  @override
  Future<void> disconnect() async {}

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
  Future<bool> validate() async {
    return true;
  }

  @override
  PlatformCapability capability() {
    return const PlatformCapability(
      maxImages: 10,
      maxVideos: 1,
      supportsScheduling: true,
      supportsMarkdown: true,
      supportsPolls: true,
      supportsDocuments: true,
      supportsHashtags: true,
      supportsMentions: true,
      maxCaptionLength: 4096,
      maxVideoSize: 2000000000,
      maxImageSize: 50000000,
    );
  }
}
