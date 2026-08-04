import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/offline/queue/outbox_store.dart';
import 'package:smart_publisher/src/offline/sync/resumable_upload_manager.dart';

import '../../helpers/fake_network_client.dart';

void main() {
  group('MediaRepositoryImpl', () {
    test(
      'upload with bytes (Flutter Web has no filesystem path to read) sends the raw bytes, never touches the filesystem',
      () async {
        FormData? capturedFormData;
        final client = FakeNetworkClient(
          uploadHandler: (path, formData) async {
            capturedFormData = formData;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 201,
              data: <String, dynamic>{
                'success': true,
                'data': {
                  'id': 'm3',
                  'post_id': 'p3',
                  'url': 'https://cdn.example.com/media/m3.png',
                  'mime_type': 'image/png',
                  'size_in_bytes': 4,
                },
              },
            );
          },
        );
        final repo = MediaRepositoryImpl(networkClient: client);

        final media = MediaEntity(
          id: 'm3',
          postId: 'p3',
          url: 'photo.png', // not a real path — just a filename, as on web
          mimeType: 'image/png',
          sizeInBytes: 4,
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        );

        final result = await repo.uploadMedia(media);

        expect(result.isSuccess, isTrue);
        final filePart = capturedFormData?.files.firstWhere(
          (entry) => entry.key == 'file',
        );
        expect(filePart, isNotNull);
        expect(filePart!.value.length, 4);
      },
    );

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

    test(
      'compressMedia posts to the real per-attachment compress endpoint',
      () async {
        String? postedPath;
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            postedPath = path;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'id': 'm4',
                  'post_id': 'p4',
                  'url': 'https://cdn.example.com/media/m4.jpg',
                  'mime_type': 'image/jpeg',
                  'size_in_bytes': 500,
                  'meta': <String, dynamic>{'compressed': true},
                },
              },
            );
          },
        );
        final repo = MediaRepositoryImpl(networkClient: client);
        const media = MediaEntity(
          id: 'm4',
          postId: 'p4',
          url: 'https://cdn.example.com/media/m4.jpg',
          mimeType: 'image/jpeg',
          sizeInBytes: 1000,
        );

        final result = await repo.compressMedia(media);

        expect(result.isSuccess, isTrue);
        expect(postedPath, '/media/m4/compress');
        expect(result.data!.isCompressed, isTrue);
      },
    );

    test(
      'getMediaLibrary parses the real list shape including thumbnails and tags',
      () async {
        String? requestedPath;
        final client = FakeNetworkClient(
          getHandler: (path) async {
            requestedPath = path;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'id': 'm5',
                    'post_id': null,
                    'url': 'https://cdn.example.com/media/m5.jpg',
                    'thumbnail_path':
                        'https://cdn.example.com/media/m5_thumb.jpg',
                    'mime_type': 'image/jpeg',
                    'size_in_bytes': 2048,
                    'collection': 'campaign',
                    'tags': <String>['vacation', 'beach'],
                    'created_at': '2026-07-26T10:00:00Z',
                  },
                ],
              },
            );
          },
        );
        final repo = MediaRepositoryImpl(networkClient: client);

        final result = await repo.getMediaLibrary(
          type: 'image',
          search: 'm5',
          tags: <String>['beach'],
        );

        expect(result.isSuccess, isTrue);
        expect(requestedPath, contains('type=image'));
        expect(requestedPath, contains('search=m5'));
        expect(requestedPath, contains('tags[]=beach'));
        final item = result.data!.single;
        expect(item.collection, 'campaign');
        expect(item.tags, <String>['vacation', 'beach']);
        expect(item.thumbnailUrl, 'https://cdn.example.com/media/m5_thumb.jpg');
      },
    );

    test(
      'attachMediaToPost posts the numeric attachment id to the attach endpoint',
      () async {
        String? postedPath;
        Map<String, dynamic>? postedData;
        final client = FakeNetworkClient(
          postHandler: (path, data) async {
            postedPath = path;
            postedData = data as Map<String, dynamic>;
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{'success': true, 'data': <dynamic>[]},
            );
          },
        );
        final repo = MediaRepositoryImpl(networkClient: client);

        final result = await repo.attachMediaToPost(mediaId: '5', postId: '9');

        expect(result.isSuccess, isTrue);
        expect(postedPath, '/posts/9/media/attach');
        expect(postedData!['attachment_ids'], <int>[5]);
      },
    );
  });
}
