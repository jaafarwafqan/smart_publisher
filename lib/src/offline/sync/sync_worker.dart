import '../queue/outbox_entry.dart';
import '../queue/outbox_store.dart';
import 'conflict_resolution.dart';

typedef OutboxSyncHandler = Future<void> Function(OutboxEntry entry);

class SyncWorker {
  const SyncWorker({
    required this.outboxStore,
    this.conflictResolver = const ConflictResolver(),
    this.maxAttempts = 3,
    this.retryBackoff = const Duration(seconds: 10),
  });

  final OutboxStore outboxStore;
  final ConflictResolver conflictResolver;
  final int maxAttempts;
  final Duration retryBackoff;

  Future<int> runOnce(Map<OutboxOperation, OutboxSyncHandler> handlers) async {
    final entries = await outboxStore.dueItems();
    var processed = 0;

    for (final entry in entries) {
      final handler = handlers[entry.operation];
      if (handler == null) {
        await outboxStore.markDeadLetter(
          entry.id,
          error: 'No sync handler for ${entry.operation.name}',
        );
        continue;
      }

      await outboxStore.markReserved(entry.id);
      await outboxStore.markProcessing(entry.id);

      try {
        await handler(entry);
        await outboxStore.markCompleted(entry.id);
        processed++;
      } catch (error) {
        final attempts = entry.attempts + 1;
        if (attempts >= maxAttempts) {
          await outboxStore.markDeadLetter(entry.id, error: error.toString());
          continue;
        }
        await outboxStore.markRetry(
          entry.id,
          nextAttemptAt: DateTime.now().add(retryBackoff),
          error: error.toString(),
        );
      }
    }

    return processed;
  }
}
