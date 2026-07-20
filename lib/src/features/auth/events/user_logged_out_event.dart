import '../../../core/events/event.dart';

class UserLoggedOutEvent extends AppEvent {
  const UserLoggedOutEvent({required this.userId});

  final String userId;

  @override
  String get type => 'user_logged_out';
}
