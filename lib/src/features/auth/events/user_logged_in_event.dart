import '../../../core/events/event.dart';

class UserLoggedInEvent extends AppEvent {
  const UserLoggedInEvent({required this.userId, required this.email});

  final String userId;
  final String email;

  @override
  String get type => 'user_logged_in';
}
