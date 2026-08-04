import 'dart:async';

import '../logger/app_logger.dart';
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
      try {
        await handler.handle(event);
      } catch (error, stackTrace) {
        // A handler failing (e.g. logging) must never make the publisher of
        // the event look like it failed too — event dispatch runs inside
        // repository write transactions, and an uncaught handler error here
        // used to surface as "post creation failed" even though the write
        // itself had already succeeded.
        AppLogger.e(
          'Event handler ${handler.runtimeType} failed for $T',
          error,
          stackTrace,
        );
      }
    }
  }
}
