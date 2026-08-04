import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/network/laravel_api.dart';
import 'package:smart_publisher/src/features/media/data/media_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';

import '../helpers/fake_network_client.dart';

void main() {
  group('Contract - API Versioning', () {
    test('versioned endpoints resolve to the api/v1 prefix via apiBaseUrl', () {
      // The /api/v1 prefix lives in LaravelApi.apiBaseUrl (the Dio base URL),
      // not in these path constants, so what matters is the final request
      // URL (base + path) rather than the bare path string.
      String fullUrl(String path) => '${LaravelApi.apiBaseUrl}$path';

      expect(fullUrl(LaravelEndpoints.posts), '${LaravelApi.apiBaseUrl}/posts');
      expect(
        fullUrl(LaravelEndpoints.postById('11')),
        '${LaravelApi.apiBaseUrl}/posts/11',
      );
      expect(
        fullUrl(LaravelEndpoints.mediaUpload),
        '${LaravelApi.apiBaseUrl}/media',
      );
      expect(LaravelApi.apiBaseUrl, endsWith('/api/v1'));
    });

    test('post and media repositories call versioned routes', () async {
      final calls = <String>[];
      final client = FakeNetworkClient(
        postHandler: (path, data) async {
          calls.add('POST $path');
          return Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'id': 'p1',
                'title': 't',
                'content': 'b',
                'status': 'draft',
              },
            },
          );
        },
        getHandler: (path) async {
          calls.add('GET $path');
          return Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{'success': true, 'data': <dynamic>[]},
          );
        },
        uploadHandler: (path, formData) async {
          calls.add('UPLOAD $path');
          return Response<dynamic>(
            requestOptions: RequestOptions(path: path),
            statusCode: 200,
            data: <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'id': 'm1',
                'post_id': 'p1',
                'url': 'https://cdn.example.com/a.jpg',
                'mime_type': 'image/jpeg',
                'size_in_bytes': 1024,
                'is_compressed': false,
              },
            },
          );
        },
      );

      final postsRepo = PostRepositoryImpl(networkClient: client);
      final mediaRepo = MediaRepositoryImpl(networkClient: client);

      await postsRepo.createPost(
        const PostEntity(id: 'p1', title: 't', body: 'b'),
      );
      await postsRepo.getPosts();
      await mediaRepo.uploadMedia(
        const MediaEntity(
          id: 'm1',
          postId: 'p1',
          url: 'https://cdn.example.com/a.jpg',
          mimeType: 'image/jpeg',
          sizeInBytes: 1024,
        ),
      );

      // FakeNetworkClient records the raw path handed to it (mirroring how
      // the real NetworkClient receives it before Dio prepends baseUrl), so
      // these are the bare LaravelEndpoints paths, not the full request URL.
      expect(calls, contains('POST /posts'));
      expect(calls, contains('GET /posts'));
      expect(calls, contains('UPLOAD /media'));
    });
  });
}
