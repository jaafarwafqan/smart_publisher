class PlatformCapability {
  const PlatformCapability({
    this.maxImages = 1,
    this.maxVideos = 1,
    this.supportsScheduling = false,
    this.supportsCarousel = false,
    this.supportsStories = false,
    this.supportsReels = false,
    this.supportsMarkdown = false,
    this.supportsPolls = false,
    this.supportsDocuments = false,
    this.supportsHashtags = false,
    this.supportsMentions = false,
    this.supportsLocation = false,
    this.maxCaptionLength = 2200,
    this.maxVideoSize = 0,
    this.maxImageSize = 0,
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
