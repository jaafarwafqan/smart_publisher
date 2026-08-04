import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/analytics_dashboard_entity.dart';
import '../entities/analytics_insight_entity.dart';
import '../entities/analytics_metric_entity.dart';
import '../entities/analytics_report_entity.dart';
import '../entities/analytics_summary_entity.dart';

abstract class AnalyticsRepository
    extends BaseRepository<AnalyticsMetricEntity> {
  const AnalyticsRepository();

  Future<AppResult<AnalyticsMetricEntity>> getPostMetrics(String postId);

  /// Fetches metrics for many posts in a single request — used by the
  /// Analytics screen instead of looping [getPostMetrics] per post.
  Future<AppResult<List<AnalyticsMetricEntity>>> getPostsMetrics(
    List<String> postIds,
  );

  Future<AppResult<AnalyticsDashboardEntity>> getDashboard();

  /// Real post-count/engagement summary (`GET /api/v1/analytics`) — distinct
  /// from [getDashboard], which hits `/api/v1/analytics/dashboard`, a route
  /// that is currently an honest stub (always returns zeros server-side,
  /// no per-post reach/impression tracking exists yet).
  Future<AppResult<AnalyticsSummaryEntity>> getSummary();

  Future<AppResult<List<AnalyticsInsightEntity>>> getInsights(String postId);

  Future<AppResult<AnalyticsReportEntity>> getReport({
    required DateTime from,
    required DateTime to,
    List<String> postIds,
  });

  Future<AppResult<AnalyticsExportEntity>> exportReport(
    AnalyticsReportEntity report,
  );
}
