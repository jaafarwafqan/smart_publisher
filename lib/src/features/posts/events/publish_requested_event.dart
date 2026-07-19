import '../../../core/events/event.dart';

class PublishRequestedEvent extends AppEvent {
  const PublishRequestedEvent({required this.postId, required this.platforms});

  final String postId;
  final List<String> platforms;

  @override
  String get type => 'publish_requested';
}
