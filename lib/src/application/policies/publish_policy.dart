import '../../features/posts/domain/entities/post_entity.dart';
import '../../features/platforms/domain/entities/platform_entity.dart';
import '../validators/platform_validator.dart';
import '../validators/title_validator.dart';

class PublishPolicy {
  const PublishPolicy({
    this.titleValidator = const TitleValidator(),
    this.platformValidator = const PlatformValidator(),
  });

  final TitleValidator titleValidator;
  final PlatformValidator platformValidator;

  String? validatePost(PostEntity post, PlatformEntity? platform) {
    final titleError = titleValidator.validate(post.title);
    if (titleError != null) {
      return titleError;
    }

    final platformError = platformValidator.validatePlatform(platform);
    if (platformError != null) {
      return platformError;
    }

    return platformValidator.validateConnection(platform!);
  }
}
