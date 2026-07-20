import 'analytics_metric_entity.dart';

class AnalyticsDashboardEntity {
  const AnalyticsDashboardEntity({
    required this.generatedAt,
    required this.totalReach,
    required this.totalEngagement,
    required this.totalImpressions,
    required this.averageEngagementRate,
    required this.topPosts,
  });

  final DateTime generatedAt;
  final int totalReach;
  final int totalEngagement;
  final int totalImpressions;
  final double averageEngagementRate;
  final List<AnalyticsMetricEntity> topPosts;
}
