import '../facebook/facebook_platform.dart';
import '../instagram/instagram_platform.dart';
import '../linkedin/linkedin_platform.dart';
import '../tiktok/tiktok_platform.dart';
import '../telegram/telegram_platform.dart';
import '../threads/threads_platform.dart';
import '../twitter/x_platform.dart';
import '../whatsapp/whatsapp_platform.dart';
import 'social_platform.dart';

const List<SocialPlatform> defaultPlatformPlugins = <SocialPlatform>[
  FacebookPlatform(),
  InstagramPlatform(),
  TelegramPlatform(),
  WhatsAppPlatform(),
  ThreadsPlatform(),
  XPlatform(),
  LinkedInPlatform(),
  TikTokPlatform(),
];
