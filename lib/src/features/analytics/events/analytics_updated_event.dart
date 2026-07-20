import '../../../core/events/event.dart';

class AnalyticsUpdatedEvent extends AppEvent {
  const AnalyticsUpdatedEvent({required this.postId, this.metrics = const {}});

  final String postId;
  final Map<String, dynamic> metrics;

  @override
  String get type => 'analytics_updated';
}
