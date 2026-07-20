import '../logger/app_logger.dart';
import 'event.dart';
import 'event_handler.dart';

class LoggingEventHandler implements EventHandler<AppEvent> {
  const LoggingEventHandler();

  @override
  Future<void> handle(AppEvent event) async {
    AppLogger.structured(
      'INFO',
      'Event received',
      context: <String, Object?>{'event_type': event.type},
    );
  }
}
