import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/offline/queue/outbox_store.dart';
import 'package:smart_publisher/src/offline/sync/resumable_upload_manager.dart';

import '../helpers/fake_network_client.dart';

void main() {
  group('P0 - Network Interruption', () {
    test(
      'upload interruption then recovery retries and completes session',
      () async {
        var uploadCalls = 0;
        final outbox = OutboxStore();
        final resumable = ResumableUploadManager();
        final client = FakeNetworkClient(
          uploadHandler: (path, formData) async {
            uploadCalls += 1;
            if (uploadCalls == 1) {
              throw DioException(
                requestOptions: RequestOptions(path: path),
                type: DioExceptionType.connectionError,
                error: 'network disconnected',
              );
            }
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'id': 'media-net-1',
                  'post_id': 'post-1',
                  'url': 'https://cdn.example.com/m.jpg',
                  'mime_type': 'image/jpeg',
                  'size_in_bytes': 12345,
                  'is_compressed': true,
                },
              },
            );
          },
        );

        final repository = MediaRepositoryImpl(
          networkClient: client,
          outboxStore: outbox,
          resumableUploadManager: resumable,
        );

        const media = MediaEntity(
          id: 'media-net-1',
          postId: 'post-1',
          url: 'https://cdn.example.com/m.jpg',
          mimeType: 'image/jpeg',
          sizeInBytes: 12345,
        );

        final interrupted = await repository.uploadMedia(media);
        expect(interrupted.isSuccess, isTrue);
        expect(interrupted.message, contains('queued'));

        final sessionAfterFailure = await resumable.getSession(media.id);
        expect(sessionAfterFailure, isNotNull);

        final recovered = await repository.uploadMedia(media);
        expect(recovered.isSuccess, isTrue);
        expect(recovered.message, contains('remotely'));
        expect(uploadCalls, 2);

        final sessionAfterRecovery = await resumable.getSession(media.id);
        expect(sessionAfterRecovery, isNull);

        final due = await outbox.dueItems();
        expect(due, isNotEmpty);
      },
    );
  });
}
