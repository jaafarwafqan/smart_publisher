import 'event.dart';
import 'event_handler.dart';

abstract class EventListener<T extends AppEvent> implements EventHandler<T> {
  const EventListener();
}
