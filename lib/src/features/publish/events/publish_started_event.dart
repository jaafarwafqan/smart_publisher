import '../../../core/events/event.dart';

class PublishStartedEvent extends AppEvent {
  const PublishStartedEvent({required this.jobId, required this.postId});

  final String jobId;
  final String postId;

  @override
  String get type => 'publish_started';
}
