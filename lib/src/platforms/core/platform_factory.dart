import 'platform_type.dart';
import 'social_platform.dart';
import '../telegram/telegram_platform.dart';

class PlatformFactory {
  const PlatformFactory();

  SocialPlatform create(PlatformType type) {
    switch (type) {
      case PlatformType.telegram:
        return TelegramPlatform();
      case PlatformType.facebook:
        throw UnimplementedError('Facebook platform not implemented yet.');
      case PlatformType.instagram:
        throw UnimplementedError('Instagram platform not implemented yet.');
      case PlatformType.whatsapp:
        throw UnimplementedError('WhatsApp platform not implemented yet.');
      case PlatformType.threads:
        throw UnimplementedError('Threads platform not implemented yet.');
      case PlatformType.twitter:
        throw UnimplementedError('Twitter platform not implemented yet.');
      case PlatformType.linkedin:
        throw UnimplementedError('LinkedIn platform not implemented yet.');
    }
  }
}
