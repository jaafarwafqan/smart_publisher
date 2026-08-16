import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/storage/storage_service.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/offline/cache/draft_storage.dart';

/// Same simulated on-disk backend as outbox_store_persistence_test.dart —
/// state survives across separate [DraftStorage] instances, the way
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
  group('DraftStorage persistence', () {
    test(
      'a saved draft survives the store being recreated (app restart)',
      () async {
        final backend = FakeStorageService();

        final beforeRestart = DraftStorage(storage: backend);
        await beforeRestart.saveDraft(
          const PostEntity(id: '1', title: 'Offline draft', body: 'Body'),
        );

        // A fresh instance backed by the same storage represents the app
        // being closed and relaunched before the draft had a chance to sync
        // — this is exactly the gap PostRepositoryImpl.getPost()/getPosts()
        // used to fall into when reading from a plain in-memory field
        // instead of this store.
        final afterRestart = DraftStorage(storage: backend);
        final draft = await afterRestart.getDraft('1');

        expect(draft, isNotNull);
        expect(draft!.title, 'Offline draft');
        expect(draft.body, 'Body');
      },
    );

    test(
      'without a storage backend, a draft does NOT survive recreation (documents the gap this guards against)',
      () async {
        final beforeRestart = DraftStorage();
        await beforeRestart.saveDraft(
          const PostEntity(id: '2', title: 'Gone', body: ''),
        );

        final afterRestart = DraftStorage();
        expect(await afterRestart.getDraft('2'), isNull);
      },
    );

    test('every field round-trips through persistence intact', () async {
      final backend = FakeStorageService();
      final store = DraftStorage(storage: backend);
      final now = DateTime.utc(2026, 8, 16, 12, 30);

      await store.saveDraft(
        PostEntity(
          id: '3',
          title: 'Full post',
          body: 'Body text',
          status: 'scheduled',
          createdAt: now,
          updatedAt: now,
          aiImproved: true,
          hasMedia: true,
          scheduledAt: now.add(const Duration(hours: 1)),
          attachments: const ['media-1'],
          platforms: const ['telegram', 'facebook'],
          targetPageIds: const ['page-1'],
          platformContent: const {'telegram': 'Telegram-specific text'},
          approvalStatus: 'pending',
          approvalRequestedAction: 'publish',
          authorName: 'Jane',
        ),
      );

      final restarted = DraftStorage(storage: backend);
      final draft = await restarted.getDraft('3');

      expect(draft, isNotNull);
      expect(draft!.status, 'scheduled');
      expect(draft.aiImproved, isTrue);
      expect(draft.hasMedia, isTrue);
      expect(draft.scheduledAt, now.add(const Duration(hours: 1)));
      expect(draft.attachments, ['media-1']);
      expect(draft.platforms, ['telegram', 'facebook']);
      expect(draft.targetPageIds, ['page-1']);
      expect(draft.platformContent, {'telegram': 'Telegram-specific text'});
      expect(draft.approvalStatus, 'pending');
      expect(draft.approvalRequestedAction, 'publish');
      expect(draft.authorName, 'Jane');
    });

    test('listDrafts returns every persisted draft after a restart', () async {
      final backend = FakeStorageService();
      final store = DraftStorage(storage: backend);

      await store.saveDraft(const PostEntity(id: 'a', title: 'A', body: ''));
      await store.saveDraft(const PostEntity(id: 'b', title: 'B', body: ''));

      final restarted = DraftStorage(storage: backend);
      final drafts = await restarted.listDrafts();

      expect(drafts.map((d) => d.id), containsAll(['a', 'b']));
    });

    test('a deleted draft does not reappear after a restart', () async {
      final backend = FakeStorageService();
      final store = DraftStorage(storage: backend);

      await store.saveDraft(const PostEntity(id: '4', title: 'Bye', body: ''));
      await store.deleteDraft('4');

      final restarted = DraftStorage(storage: backend);
      expect(await restarted.getDraft('4'), isNull);
      expect(await restarted.listDrafts(), isEmpty);
    });

    test(
      'corrupted persisted state is discarded rather than crashing startup',
      () async {
        final backend = FakeStorageService();
        await backend.writeString('draft_posts_v1', 'not valid json {{{');

        final store = DraftStorage(storage: backend);
        expect(await store.listDrafts(), isEmpty);
      },
    );
  });
}
