import '../../../../core/base/base_repository.dart';
import '../../../../core/result/app_result.dart';

abstract class AnalyticsRepository
    extends BaseRepository<Map<String, dynamic>> {
  const AnalyticsRepository();

  Future<AppResult<Map<String, dynamic>>> getAnalytics(String postId);
}
