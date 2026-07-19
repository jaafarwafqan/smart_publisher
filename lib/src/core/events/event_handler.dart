import 'event.dart';

abstract interface class EventHandler<T extends AppEvent> {
  Future<void> handle(T event);
}
