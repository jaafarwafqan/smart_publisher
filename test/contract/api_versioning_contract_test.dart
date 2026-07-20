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
    test('versioned endpoints use api/v1 prefix', () {
      expect(LaravelEndpoints.posts, '/api/v1/posts');
      expect(LaravelEndpoints.postById('11'), '/api/v1/posts/11');
      expect(LaravelEndpoints.mediaUpload, '/api/v1/media/upload');
      expect(LaravelEndpoints.publishJobs, '/api/v1/publish/jobs');
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

      expect(calls, contains('POST /api/v1/posts'));
      expect(calls, contains('GET /api/v1/posts'));
      expect(calls, contains('UPLOAD /api/v1/media/upload'));
    });
  });
}
