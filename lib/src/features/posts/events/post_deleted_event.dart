import '../../../core/events/event.dart';

class PostDeletedEvent extends AppEvent {
  const PostDeletedEvent({required this.postId});

  final String postId;

  @override
  String get type => 'post_deleted';
}
