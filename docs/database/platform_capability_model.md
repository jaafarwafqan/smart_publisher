# Platform Capability Model

```dart
class PlatformCapability {
  const PlatformCapability({
    required this.maxImages,
    required this.maxVideos,
    required this.supportsScheduling,
    required this.supportsCarousel,
    required this.supportsStories,
    required this.supportsReels,
    required this.supportsMarkdown,
    required this.supportsPolls,
    required this.supportsDocuments,
    required this.supportsHashtags,
    required this.supportsMentions,
    required this.supportsLocation,
    required this.maxCaptionLength,
    required this.maxVideoSize,
    required this.maxImageSize,
  });

  final int maxImages;
  final int maxVideos;
  final bool supportsScheduling;
  final bool supportsCarousel;
  final bool supportsStories;
  final bool supportsReels;
  final bool supportsMarkdown;
  final bool supportsPolls;
  final bool supportsDocuments;
  final bool supportsHashtags;
  final bool supportsMentions;
  final bool supportsLocation;
  final int maxCaptionLength;
  final int maxVideoSize;
  final int maxImageSize;
}
```

## Platform-specific Files
- facebook_capability.dart
- instagram_capability.dart
- telegram_capability.dart
- whatsapp_capability.dart
- threads_capability.dart
- x_capability.dart
- linkedin_capability.dart
