import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/analytics_report_entity.dart';
import '../repositories/analytics_repository.dart';

class ExportReport
    extends BaseUseCase<AnalyticsReportEntity, AnalyticsExportEntity> {
  const ExportReport({required this.repository});

  final AnalyticsRepository repository;

  @override
  Future<AppResult<AnalyticsExportEntity>> call(AnalyticsReportEntity params) {
    return repository.exportReport(params);
  }
}
