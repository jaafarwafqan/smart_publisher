import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/storage/storage_service.dart';
import 'package:smart_publisher/src/offline/queue/outbox_entry.dart';
import 'package:smart_publisher/src/offline/queue/outbox_store.dart';
import 'package:smart_publisher/src/offline/queue/queue_state_machine.dart';

/// Simulates a real on-disk/OS-backed store: state survives across separate
/// [OutboxStore] instances (unlike a plain Dart field), the way
/// flutter_secure_storage survives an app restart.
class FakeStorageService implements StorageService {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> writeString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<String?> readString(String key) async => _values[key];

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

void main() {
  group('OutboxStore persistence', () {
    test(
      'an enqueued entry survives the store being recreated (app restart)',
      () async {
        final backend = FakeStorageService();

        final beforeRestart = OutboxStore(storage: backend);
        await beforeRestart.enqueue(
          OutboxEntry(
            id: 'createPost:1',
            operation: OutboxOperation.createPost,
            payload: <String, dynamic>{'id': '1', 'title': 'Offline post'},
          ),
        );

        // A fresh instance backed by the same storage represents the app
        // being closed and relaunched (or a browser tab reload) before the
        // outbox had a chance to sync.
        final afterRestart = OutboxStore(storage: backend);
        final due = await afterRestart.dueItems();

        expect(due, hasLength(1));
        expect(due.single.id, 'createPost:1');
        expect(due.single.payload['title'], 'Offline post');
      },
    );

    test(
      'without a storage backend, entries do NOT survive recreation (documents the gap this guards against)',
      () async {
        final beforeRestart = OutboxStore();
        await beforeRestart.enqueue(
          OutboxEntry(
            id: 'createPost:2',
            operation: OutboxOperation.createPost,
            payload: <String, dynamic>{'id': '2'},
          ),
        );

        final afterRestart = OutboxStore();
        final due = await afterRestart.dueItems();

        expect(due, isEmpty);
      },
    );

    test('retry state, attempts and error survive a restart', () async {
      final backend = FakeStorageService();
      final store = OutboxStore(storage: backend);

      await store.enqueue(
        OutboxEntry(
          id: 'uploadMedia:1',
          operation: OutboxOperation.uploadMedia,
          payload: <String, dynamic>{'path': '/tmp/a.png'},
        ),
      );
      await store.markReserved('uploadMedia:1');
      await store.markProcessing('uploadMedia:1');
      await store.markRetry(
        'uploadMedia:1',
        nextAttemptAt: DateTime.now().subtract(const Duration(seconds: 1)),
        error: 'network timeout',
      );

      final restarted = OutboxStore(storage: backend);
      final due = await restarted.dueItems();

      expect(due, hasLength(1));
      expect(due.single.state, QueueState.pending);
      expect(due.single.attempts, 1);
      expect(due.single.lastError, 'network timeout');
    });

    test('a completed entry is removed and does not persist forever', () async {
      final backend = FakeStorageService();
      final store = OutboxStore(storage: backend);

      await store.enqueue(
        OutboxEntry(
          id: 'deletePost:1',
          operation: OutboxOperation.deletePost,
          payload: <String, dynamic>{'id': '1'},
        ),
      );
      await store.markReserved('deletePost:1');
      await store.markProcessing('deletePost:1');
      await store.markCompleted('deletePost:1');

      final restarted = OutboxStore(storage: backend);
      expect(await restarted.getById('deletePost:1'), isNull);
      expect(await restarted.dueItems(), isEmpty);
    });

    test(
      'a dead-lettered entry is preserved (not silently discarded)',
      () async {
        final backend = FakeStorageService();
        final store = OutboxStore(storage: backend);

        await store.enqueue(
          OutboxEntry(
            id: 'createPost:dead',
            operation: OutboxOperation.createPost,
            payload: <String, dynamic>{'id': 'dead'},
          ),
        );
        await store.markDeadLetter(
          'createPost:dead',
          error: 'gave up after max attempts',
        );

        final restarted = OutboxStore(storage: backend);
        final entry = await restarted.getById('createPost:dead');

        expect(entry, isNotNull);
        expect(entry!.state, QueueState.deadLetter);
        expect(entry.lastError, 'gave up after max attempts');
      },
    );
  });
}
