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

  /// [currentOrganizationId] reads whichever organization is active on the
  /// device *right now*. An entry queued while org A was active must never
  /// replay while the device has since switched to org B — that would
  /// create org A's content inside org B. Entries are simply skipped (not
  /// retried/dead-lettered — this isn't a failure, just "not yet, wrong
  /// org") until the device switches back. Entries with no recorded
  /// organizationId (queued before this check existed) always replay,
  /// matching the prior behavior for that legacy data.
  Future<int> runOnce(
    Map<OutboxOperation, OutboxSyncHandler> handlers, {
    Future<int?> Function()? currentOrganizationId,
  }) async {
    final entries = await outboxStore.dueItems();
    var processed = 0;
    int? activeOrganizationId;
    var activeOrganizationIdResolved = false;

    for (final entry in entries) {
      if (entry.organizationId != null && currentOrganizationId != null) {
        if (!activeOrganizationIdResolved) {
          activeOrganizationId = await currentOrganizationId();
          activeOrganizationIdResolved = true;
        }
        if (activeOrganizationId != null &&
            activeOrganizationId != entry.organizationId) {
          continue;
        }
      }

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
