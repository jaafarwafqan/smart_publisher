import '../../../core/events/event.dart';

class MediaUploadedEvent extends AppEvent {
  const MediaUploadedEvent({required this.mediaId, required this.postId});

  final String mediaId;
  final String postId;

  @override
  String get type => 'media_uploaded';
}
