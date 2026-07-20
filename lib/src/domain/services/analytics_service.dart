import '../../core/result/app_result.dart';
import '../../features/analytics/domain/entities/analytics_dashboard_entity.dart';
import '../../features/analytics/domain/entities/analytics_insight_entity.dart';
import '../../features/analytics/domain/entities/analytics_metric_entity.dart';
import '../../features/analytics/domain/entities/analytics_report_entity.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';

class AnalyticsService {
  const AnalyticsService({required this.repository});

  final AnalyticsRepository repository;

  Future<AppResult<AnalyticsMetricEntity>> metrics(String postId) {
    return repository.getPostMetrics(postId);
  }

  Future<AppResult<AnalyticsDashboardEntity>> dashboard() {
    return repository.getDashboard();
  }

  Future<AppResult<List<AnalyticsInsightEntity>>> insights(String postId) {
    return repository.getInsights(postId);
  }

  Future<AppResult<AnalyticsReportEntity>> report({
    required DateTime from,
    required DateTime to,
    List<String> postIds = const <String>[],
  }) {
    return repository.getReport(from: from, to: to, postIds: postIds);
  }

  Future<AppResult<AnalyticsExportEntity>> export(
    AnalyticsReportEntity report,
  ) {
    return repository.exportReport(report);
  }
}
