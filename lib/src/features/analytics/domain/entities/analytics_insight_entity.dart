enum AnalyticsInsightType { trend, recommendation, alert }

class AnalyticsInsightEntity {
  const AnalyticsInsightEntity({
    required this.title,
    required this.description,
    required this.type,
    required this.value,
  });

  final String title;
  final String description;
  final AnalyticsInsightType type;
  final num value;
}
