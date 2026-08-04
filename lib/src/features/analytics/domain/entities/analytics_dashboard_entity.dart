import 'analytics_metric_entity.dart';

class AnalyticsDashboardEntity {
  const AnalyticsDashboardEntity({
    required this.generatedAt,
    required this.totalReach,
    required this.totalEngagement,
    required this.totalImpressions,
    required this.averageEngagementRate,
    required this.topPosts,
    this.bestPlatform,
    this.bestPublishHour,
  });

  final DateTime generatedAt;
  final int totalReach;
  final int totalEngagement;
  final int totalImpressions;
  final double averageEngagementRate;
  final List<AnalyticsMetricEntity> topPosts;

  /// Null means there isn't yet enough real engagement data to make an
  /// honest recommendation — never a fabricated guess.
  final String? bestPlatform;
  final int? bestPublishHour;
}
