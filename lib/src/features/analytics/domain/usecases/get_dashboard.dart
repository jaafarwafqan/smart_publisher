import '../../../../core/base/base_usecase.dart';
import '../../../../core/result/app_result.dart';
import '../entities/analytics_dashboard_entity.dart';
import '../repositories/analytics_repository.dart';

class GetDashboard extends BaseUseCase<void, AnalyticsDashboardEntity> {
  const GetDashboard({required this.repository});

  final AnalyticsRepository repository;

  @override
  Future<AppResult<AnalyticsDashboardEntity>> call(void params) {
    return repository.getDashboard();
  }
}
