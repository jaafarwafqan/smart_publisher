import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/analytics_insight_entity.dart';
import '../repositories/analytics_repository.dart';

class GetInsights extends BaseUseCase<String, List<AnalyticsInsightEntity>> {
  const GetInsights({required this.repository});

  final AnalyticsRepository repository;

  @override
  Future<AppResult<List<AnalyticsInsightEntity>>> call(String params) {
    return repository.getInsights(params);
  }
}
