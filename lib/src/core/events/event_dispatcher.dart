import 'event.dart';
import 'event_bus.dart';

class EventDispatcher {
  const EventDispatcher(this.bus);

  final EventBus bus;

  Future<void> dispatch<T extends AppEvent>(T event) async {
    await bus.dispatch(event);
  }
}
