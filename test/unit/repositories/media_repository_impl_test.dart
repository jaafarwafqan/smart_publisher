import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/offline/queue/outbox_store.dart';
import 'package:smart_publisher/src/offline/sync/resumable_upload_manager.dart';

void main() {
  group('MediaRepositoryImpl', () {
    test('compress marks media as compressed in local mode', () async {
      final repo = MediaRepositoryImpl();
      const media = MediaEntity(
        id: 'm1',
        postId: 'p1',
        url: 'https://cdn.example.com/video.mp4',
        mimeType: 'video/mp4',
        sizeInBytes: 2000000,
      );

      final result = await repo.compressMedia(media);

      expect(result.isSuccess, isTrue);
      expect(result.data?.isCompressed, isTrue);
      expect(result.data!.sizeInBytes, lessThan(media.sizeInBytes));
    });

    test('upload queues resumable session in local mode', () async {
      final outbox = OutboxStore();
      final resumable = ResumableUploadManager();
      final repo = MediaRepositoryImpl(
        outboxStore: outbox,
        resumableUploadManager: resumable,
      );

      const media = MediaEntity(
        id: 'm2',
        postId: 'p2',
        url: 'https://cdn.example.com/image.jpg',
        mimeType: 'image/jpeg',
        sizeInBytes: 100000,
      );

      final result = await repo.uploadMedia(media);
      expect(result.isSuccess, isTrue);

      final session = await resumable.getSession(media.id);
      expect(session, isNotNull);

      final due = await outbox.dueItems();
      expect(due, isNotEmpty);
    });
  });
}
