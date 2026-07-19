import '../../../core/events/event.dart';

class PostCreatedEvent extends AppEvent {
  const PostCreatedEvent({required this.postId});

  final String postId;

  @override
  String get type => 'post_created';
}
