import '../../features/posts/domain/entities/post_entity.dart';
import 'auth_result.dart';
import 'platform_capability.dart';
import 'publish_result.dart';

abstract interface class SocialPlatform {
  Future<AuthResult> connect();

  Future<void> disconnect();

  Future<PublishResult> publish(PostEntity post);

  Future<bool> validate();

  PlatformCapability capability();
}
