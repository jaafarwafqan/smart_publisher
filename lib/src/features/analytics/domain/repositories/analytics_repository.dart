import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';
import '../entities/analytics_dashboard_entity.dart';
import '../entities/analytics_insight_entity.dart';
import '../entities/analytics_metric_entity.dart';
import '../entities/analytics_report_entity.dart';

abstract class AnalyticsRepository
    extends BaseRepository<AnalyticsMetricEntity> {
  const AnalyticsRepository();

  Future<AppResult<AnalyticsMetricEntity>> getPostMetrics(String postId);

  Future<AppResult<AnalyticsDashboardEntity>> getDashboard();

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
