import 'dart:async';

import 'event.dart';
import 'event_handler.dart';

class EventBus {
  EventBus();

  final _handlers = <Type, List<EventHandler<AppEvent>>>{};

  void register<T extends AppEvent>(EventHandler<T> handler) {
    final handlers = _handlers[T] ?? <EventHandler<AppEvent>>[];
    handlers.add(handler as EventHandler<AppEvent>);
    _handlers[T] = handlers;
  }

  Future<void> dispatch<T extends AppEvent>(T event) async {
    final handlers = _handlers[T];
    if (handlers == null || handlers.isEmpty) {
      return;
    }

    for (final handler in handlers) {
      await handler.handle(event);
    }
  }
}
