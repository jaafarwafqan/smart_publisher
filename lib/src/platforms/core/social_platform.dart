import '../../features/posts/domain/entities/post_entity.dart';
import '../../domain/publish_target.dart';
import 'auth_result.dart';
import 'platform_capability.dart';
import 'publish_result.dart';

abstract interface class SocialPlatform {
  String get platformId;

  Set<String> get supportedTargetKeys;

  Future<AuthResult> connect();

  Future<void> disconnect();

  Future<PublishResult> publish(PostEntity post);

  bool supportsTarget(PublishTarget target);

  Future<bool> validate();

  PlatformCapability capability();
}
