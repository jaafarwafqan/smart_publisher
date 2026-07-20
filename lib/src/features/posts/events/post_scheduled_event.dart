import '../../../core/events/event.dart';

class PostScheduledEvent extends AppEvent {
  const PostScheduledEvent({required this.postId, required this.scheduledAt});

  final String postId;
  final DateTime? scheduledAt;

  @override
  String get type => 'post_scheduled';
}
