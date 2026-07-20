import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/analytics_metric_entity.dart';
import '../repositories/analytics_repository.dart';

class GetPostMetrics extends BaseUseCase<String, AnalyticsMetricEntity> {
  const GetPostMetrics({required this.repository});

  final AnalyticsRepository repository;

  @override
  Future<AppResult<AnalyticsMetricEntity>> call(String params) {
    return repository.getPostMetrics(params);
  }
}
