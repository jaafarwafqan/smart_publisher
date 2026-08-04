import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/offline/queue/outbox_store.dart';
import 'package:smart_publisher/src/offline/sync/outbox_sync_handlers.dart';
import 'package:smart_publisher/src/offline/sync/resumable_upload_manager.dart';
import 'package:smart_publisher/src/offline/sync/sync_worker.dart';

import '../../helpers/fake_network_client.dart';

void main() {
  test(
    'a web upload (bytes, no real path) that goes offline is retried successfully once back online, with the same bytes',
    () async {
      final outbox = OutboxStore();
      final originalBytes = Uint8List.fromList(<int>[10, 20, 30, 40, 50]);

      // First attempt: the network is down, so this must fall back to
      // queueing the upload in the outbox instead of throwing.
      final offlineClient = FakeNetworkClient(
        uploadHandler: (path, formData) async {
          throw DioException(
            requestOptions: RequestOptions(path: path),
            type: DioExceptionType.connectionError,
          );
        },
      );
      final offlineRepo = MediaRepositoryImpl(
        networkClient: offlineClient,
        outboxStore: outbox,
        resumableUploadManager: ResumableUploadManager(),
      );

      final media = MediaEntity(
        id: 'web-media-1',
        postId: 'post-1',
        url: 'screenshot.png', // a filename, not a real path — as on web
        mimeType: 'image/png',
        sizeInBytes: originalBytes.length,
        bytes: originalBytes,
      );

      final queuedResult = await offlineRepo.uploadMedia(media);
      expect(queuedResult.isSuccess, isTrue);

      final due = await outbox.dueItems();
      expect(due, hasLength(1));
      expect(
        due.single.payload['bytes_base64'],
        isNotNull,
        reason:
            'the raw bytes must travel with the queued entry — there is '
            'no filesystem path to re-read them from later on web',
      );

      // Now simulate connectivity coming back: a second repository (as
      // SyncWorker would use) backed by a client that succeeds this time.
      Uint8List? receivedBytes;
      final onlineClient = FakeNetworkClient(
        uploadHandler: (path, formData) async {
          final filePart = formData.files.firstWhere((e) => e.key == 'file');
          receivedBytes = Uint8List.fromList(
            await filePart.value.finalize().expand((chunk) => chunk).toList(),
          );
          return Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 201,
            data: <String, dynamic>{
              'success': true,
              'data': {
                'id': 'web-media-1',
                'post_id': 'post-1',
                'url': 'https://cdn.example.com/media/web-media-1.png',
                'mime_type': 'image/png',
                'size_in_bytes': originalBytes.length,
              },
            },
          );
        },
      );
      final onlineRepo = MediaRepositoryImpl(networkClient: onlineClient);

      final handlers = buildOutboxSyncHandlers(
        postRepository: PostRepositoryImpl(),
        mediaRepository: onlineRepo,
      );
      final worker = SyncWorker(outboxStore: outbox);
      final processed = await worker.runOnce(handlers);

      expect(processed, 1);
      expect(receivedBytes, equals(originalBytes));
    },
  );
}
