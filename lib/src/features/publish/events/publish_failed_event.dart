import '../../../core/events/event.dart';

class PublishFailedEvent extends AppEvent {
  const PublishFailedEvent({
    required this.jobId,
    required this.postId,
    required this.errorCode,
    required this.errorMessage,
  });

  final String jobId;
  final String postId;
  final String errorCode;
  final String errorMessage;

  @override
  String get type => 'publish_failed';
}
