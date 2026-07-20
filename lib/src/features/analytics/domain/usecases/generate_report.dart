import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/analytics_report_entity.dart';
import '../repositories/analytics_repository.dart';

class GenerateReportParams {
  const GenerateReportParams({
    required this.from,
    required this.to,
    this.postIds = const <String>[],
  });

  final DateTime from;
  final DateTime to;
  final List<String> postIds;
}

class GenerateReport
    extends BaseUseCase<GenerateReportParams, AnalyticsReportEntity> {
  const GenerateReport({required this.repository});

  final AnalyticsRepository repository;

  @override
  Future<AppResult<AnalyticsReportEntity>> call(GenerateReportParams params) {
    return repository.getReport(
      from: params.from,
      to: params.to,
      postIds: params.postIds,
    );
  }
}
