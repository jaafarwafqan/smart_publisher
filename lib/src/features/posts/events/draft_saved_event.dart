import '../../../core/events/event.dart';

class DraftSavedEvent extends AppEvent {
  const DraftSavedEvent({required this.postId});

  final String postId;

  @override
  String get type => 'draft_saved';
}
