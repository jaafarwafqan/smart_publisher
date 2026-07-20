import 'dart:async';

final class TraceContext {
  TraceContext._();

  static const String _traceKey = '_trace_id';

  static String? currentTraceId() {
    return Zone.current[_traceKey] as String?;
  }

  static String ensureTraceId() {
    final existing = currentTraceId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    return newTraceId();
  }

  static String newTraceId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'trc-$now';
  }

  static R runWithTrace<R>(R Function() action, {String? traceId}) {
    final existing = currentTraceId();
    if (existing != null && existing.isNotEmpty) {
      if (traceId == null || traceId == existing) {
        return action();
      }
    }

    final id = traceId ?? existing ?? newTraceId();
    return runZoned<R>(action, zoneValues: <Object?, Object?>{_traceKey: id});
  }
}
