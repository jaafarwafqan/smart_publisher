class AnalyticsService {
  const AnalyticsService();

  Future<Map<String, Object?>> track(String eventName) async {
    return {'event': eventName};
  }
}
