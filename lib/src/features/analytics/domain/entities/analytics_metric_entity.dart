class AnalyticsMetricEntity {
  const AnalyticsMetricEntity({
    required this.postId,
    required this.impressions,
    required this.clicks,
    required this.shares,
    required this.reactions,
    required this.reach,
    required this.engagement,
    required this.status,
  });

  final String postId;
  final int impressions;
  final int clicks;
  final int shares;
  final int reactions;
  final int reach;
  final int engagement;
  final String status;

  double get engagementRate {
    if (reach <= 0) {
      return 0;
    }
    return engagement / reach;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'post_id': postId,
      'impressions': impressions,
      'clicks': clicks,
      'shares': shares,
      'reactions': reactions,
      'reach': reach,
      'engagement': engagement,
      'engagement_rate': engagementRate,
      'status': status,
    };
  }
}
