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
    final typedHandlers = _handlers[T] ?? const <EventHandler<AppEvent>>[];
    final wildcardHandlers =
        _handlers[AppEvent] ?? const <EventHandler<AppEvent>>[];

    final handlers = <EventHandler<AppEvent>>[
      ...typedHandlers,
      if (T != AppEvent) ...wildcardHandlers,
    ];

    if (handlers.isEmpty) {
      return;
    }

    for (final handler in handlers) {
      await handler.handle(event);
    }
  }
}
