import 'dart:async';

class BackgroundTaskManager {
  BackgroundTaskManager() : _timers = <Timer>[];

  final List<Timer> _timers;

  void schedulePeriodic(Duration interval, void Function() action) {
    final timer = Timer.periodic(interval, (_) => action());
    _timers.add(timer);
  }

  void scheduleDelayed(Duration delay, void Function() action) {
    final timer = Timer(delay, action);
    _timers.add(timer);
  }

  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }
}
