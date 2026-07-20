import '../../../core/events/event.dart';

class PublishSucceededEvent extends AppEvent {
  const PublishSucceededEvent({required this.jobId, required this.postId});

  final String jobId;
  final String postId;

  @override
  String get type => 'publish_succeeded';
}
