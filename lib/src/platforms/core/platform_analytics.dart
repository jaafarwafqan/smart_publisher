class PlatformAnalytics {
  const PlatformAnalytics({
    required this.platform,
    required this.externalPostId,
    required this.metrics,
  });

  final String platform;
  final String externalPostId;
  final Map<String, num> metrics;
}
