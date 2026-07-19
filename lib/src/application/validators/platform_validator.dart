import '../../features/platforms/domain/entities/platform_entity.dart';

class PlatformValidator {
  const PlatformValidator();

  String? validatePlatform(PlatformEntity? platform) {
    if (platform == null) {
      return 'Platform is required.';
    }

    if (platform.name.trim().isEmpty) {
      return 'Platform name is required.';
    }

    return null;
  }

  String? validateConnection(PlatformEntity platform) {
    if (!platform.isConnected) {
      return 'Platform must be connected before publishing.';
    }

    return null;
  }
}
