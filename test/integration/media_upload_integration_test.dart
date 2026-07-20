import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/offline/queue/outbox_store.dart';
import 'package:smart_publisher/src/offline/sync/resumable_upload_manager.dart';

void main() {
  group('Integration - Media Upload', () {
    test(
      'upload uses media engine then stores outbox/session locally',
      () async {
        final outbox = OutboxStore();
        final resumable = ResumableUploadManager();
        final repository = MediaRepositoryImpl(
          outboxStore: outbox,
          resumableUploadManager: resumable,
        );

        const media = MediaEntity(
          id: 'media-int-1',
          postId: 'post-int-1',
          url: 'https://cdn.example.com/image.jpg',
          mimeType: 'image/jpeg',
          sizeInBytes: 400000,
        );

        final result = await repository.uploadMedia(media);
        expect(result.isSuccess, isTrue);
        expect(result.data?.isCompressed, isTrue);

        final queued = await outbox.dueItems();
        expect(queued.length, greaterThan(0));

        final session = await resumable.getSession(media.id);
        expect(session, isNotNull);
      },
    );
  });
}
