import '../../../core/events/event_dispatcher.dart';
import '../events/user_logged_in_event.dart';
import '../events/user_logged_out_event.dart';

class AuthEventPublisher {
  const AuthEventPublisher(this._eventDispatcher);

  final EventDispatcher _eventDispatcher;

  Future<void> publishLoggedIn({
    required String userId,
    required String email,
  }) {
    return _eventDispatcher.dispatch(
      UserLoggedInEvent(userId: userId, email: email),
    );
  }

  Future<void> publishLoggedOut({required String userId}) {
    return _eventDispatcher.dispatch(UserLoggedOutEvent(userId: userId));
  }
}
