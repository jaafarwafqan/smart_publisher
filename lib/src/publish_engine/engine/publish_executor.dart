import '../../platforms/core/platform_factory.dart';
import '../engine/publish_context.dart';
import '../engine/publish_step.dart';

class PublishStepImpl implements PublishStep {
  const PublishStepImpl({required this.platformFactory});

  final PlatformFactory platformFactory;

  @override
  Future<void> execute(PublishContext context) async {
    for (final platform in context.platforms) {
      final platformImpl = platformFactory.create(platform);
      final result = await platformImpl.publish(context.post);
      if (!result.success) {
        throw StateError(
          'Publishing failed for ${platform.name}: ${result.message}',
        );
      }
    }
  }
}
