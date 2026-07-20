import 'outbox_entry.dart';
import 'queue_state_machine.dart';

class OutboxStore {
  OutboxStore({QueueStateMachine? stateMachine})
    : _items = <String, OutboxEntry>{},
      _order = <String>[],
      _stateMachine = stateMachine ?? const QueueStateMachine();

  final Map<String, OutboxEntry> _items;
  final List<String> _order;
  final QueueStateMachine _stateMachine;

  Future<void> enqueue(OutboxEntry entry) async {
    _items[entry.id] = entry;
    if (!_order.contains(entry.id)) {
      _order.add(entry.id);
    }
  }

  Future<OutboxEntry?> getById(String id) async {
    return _items[id];
  }

  Future<List<OutboxEntry>> dueItems({DateTime? now}) async {
    final current = now ?? DateTime.now();
    return _order
        .map((id) => _items[id])
        .whereType<OutboxEntry>()
        .where((entry) {
          if (entry.state == QueueState.pending) {
            return true;
          }
          if (entry.state != QueueState.retry) {
            return false;
          }
          final dueAt = entry.nextAttemptAt;
          return dueAt == null || !dueAt.isAfter(current);
        })
        .toList(growable: false);
  }

  Future<bool> transition(String id, QueueState nextState) async {
    final current = _items[id];
    if (current == null) {
      return false;
    }

    if (!_stateMachine.canTransition(current.state, nextState)) {
      return false;
    }

    _items[id] = current.copyWith(state: nextState);
    return true;
  }

  Future<void> markReserved(String id) async {
    await transition(id, QueueState.reserved);
  }

  Future<void> markProcessing(String id) async {
    await transition(id, QueueState.processing);
  }

  Future<void> markCompleted(String id) async {
    final current = _items[id];
    if (current == null) {
      return;
    }
    if (_stateMachine.canTransition(current.state, QueueState.completed)) {
      _items[id] = current.copyWith(
        state: QueueState.completed,
        clearError: true,
        clearNextAttempt: true,
      );
    }
  }

  Future<void> markRetry(
    String id, {
    required DateTime nextAttemptAt,
    required String error,
  }) async {
    final current = _items[id];
    if (current == null) {
      return;
    }

    if (_stateMachine.canTransition(current.state, QueueState.retry)) {
      final retried = current.copyWith(
        state: QueueState.retry,
        attempts: current.attempts + 1,
        nextAttemptAt: nextAttemptAt,
        lastError: error,
      );
      _items[id] = retried;
      if (_stateMachine.canTransition(retried.state, QueueState.pending)) {
        _items[id] = retried.copyWith(state: QueueState.pending);
      }
    }
  }

  Future<void> markDeadLetter(String id, {required String error}) async {
    final current = _items[id];
    if (current == null) {
      return;
    }
    if (_stateMachine.canTransition(current.state, QueueState.deadLetter)) {
      _items[id] = current.copyWith(
        state: QueueState.deadLetter,
        attempts: current.attempts + 1,
        lastError: error,
      );
    }
  }
}
