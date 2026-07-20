import 'analytics_metric_entity.dart';

class AnalyticsReportEntity {
  const AnalyticsReportEntity({
    required this.id,
    required this.from,
    required this.to,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final DateTime from;
  final DateTime to;
  final List<AnalyticsMetricEntity> items;
  final DateTime createdAt;
}

class AnalyticsExportEntity {
  const AnalyticsExportEntity({
    required this.fileName,
    required this.mimeType,
    required this.content,
  });

  final String fileName;
  final String mimeType;
  final String content;
}
