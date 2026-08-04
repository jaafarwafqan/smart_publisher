import 'dart:convert';

import '../../core/storage/storage_service.dart';
import 'outbox_entry.dart';
import 'queue_state_machine.dart';

class OutboxStore {
  OutboxStore({QueueStateMachine? stateMachine, this._storage})
    : _items = <String, OutboxEntry>{},
      _order = <String>[],
      _stateMachine = stateMachine ?? const QueueStateMachine();

  static const _storageKey = 'outbox_entries_v1';

  final Map<String, OutboxEntry> _items;
  final List<String> _order;
  final QueueStateMachine _stateMachine;
  final StorageService? _storage;
  Future<void>? _hydration;

  Future<void> _ensureHydrated() {
    return _hydration ??= _hydrate();
  }

  Future<void> _hydrate() async {
    final storage = _storage;
    if (storage == null) {
      return;
    }

    final raw = await storage.readString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final item in decoded) {
        final entry = OutboxEntry.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
        _items[entry.id] = entry;
        if (!_order.contains(entry.id)) {
          _order.add(entry.id);
        }
      }
    } catch (_) {
      // Persisted outbox state is corrupted/unreadable — start clean rather
      // than crash app startup over queued data we can no longer trust.
    }
  }

  Future<void> _persist() async {
    final storage = _storage;
    if (storage == null) {
      return;
    }

    final serialized = _order
        .map((id) => _items[id])
        .whereType<OutboxEntry>()
        .map((entry) => entry.toJson())
        .toList(growable: false);
    await storage.writeString(_storageKey, jsonEncode(serialized));
  }

  Future<void> enqueue(OutboxEntry entry) async {
    await _ensureHydrated();
    _items[entry.id] = entry;
    if (!_order.contains(entry.id)) {
      _order.add(entry.id);
    }
    await _persist();
  }

  Future<OutboxEntry?> getById(String id) async {
    await _ensureHydrated();
    return _items[id];
  }

  Future<List<OutboxEntry>> dueItems({DateTime? now}) async {
    await _ensureHydrated();
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
    await _ensureHydrated();
    final current = _items[id];
    if (current == null) {
      return false;
    }

    if (!_stateMachine.canTransition(current.state, nextState)) {
      return false;
    }

    _items[id] = current.copyWith(state: nextState);
    await _persist();
    return true;
  }

  Future<void> markReserved(String id) async {
    await transition(id, QueueState.reserved);
  }

  Future<void> markProcessing(String id) async {
    await transition(id, QueueState.processing);
  }

  Future<void> markCompleted(String id) async {
    await _ensureHydrated();
    final current = _items[id];
    if (current == null) {
      return;
    }
    if (_stateMachine.canTransition(current.state, QueueState.completed)) {
      // A completed operation has already reached the server — there is
      // nothing left to recover, so drop it instead of persisting it forever.
      _items.remove(id);
      _order.remove(id);
      await _persist();
    }
  }

  Future<void> markRetry(
    String id, {
    required DateTime nextAttemptAt,
    required String error,
  }) async {
    await _ensureHydrated();
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
      await _persist();
    }
  }

  Future<void> markDeadLetter(String id, {required String error}) async {
    await _ensureHydrated();
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
      await _persist();
    }
  }
}
