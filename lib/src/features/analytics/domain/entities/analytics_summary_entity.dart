class AnalyticsSummaryEntity {
  const AnalyticsSummaryEntity({
    required this.totalPosts,
    required this.published,
    required this.failed,
    required this.scheduled,
    required this.draft,
    required this.engagementScore,
    required this.engagementTrend,
    required this.updatedAt,
  });

  final int totalPosts;
  final int published;
  final int failed;
  final int scheduled;
  final int draft;
  final double engagementScore;
  final String engagementTrend;
  final DateTime updatedAt;
}
