import '../../domain/publish_target.dart';
import 'default_platform_plugins.dart';
import 'platform_registry.dart';
import 'social_platform.dart';

class PlatformFactory {
  PlatformFactory({
    Iterable<SocialPlatform> plugins = defaultPlatformPlugins,
    PlatformRegistry? registry,
  }) : registry = registry ?? PlatformRegistry(platforms: plugins);

  final PlatformRegistry registry;

  List<ResolvedPublisher> createForTarget(PublishTarget target) {
    return registry.resolve(target);
  }

  SocialPlatform createById(String platformId) {
    return registry.get(platformId);
  }
}
