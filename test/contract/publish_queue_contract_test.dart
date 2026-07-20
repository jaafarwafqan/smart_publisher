import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/publish/data/laravel_publish_repository.dart';
import 'package:smart_publisher/src/features/publish/domain/entities/publish_job_entity.dart'
    as job;

import '../helpers/fake_network_client.dart';

void main() {
  group('Contract - Laravel Queue Integration', () {
    test(
      'create/list/get/delete queue jobs over versioned publish endpoints',
      () async {
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
                  'id': 'job-1',
                  'post_id': 'post-1',
                  'status': 'queued',
                  'retry_count': 0,
                  'progress': 0,
                },
              },
            );
          },
          patchHandler: (path, data) async {
            calls.add('PATCH $path');
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'id': 'job-1',
                  'post_id': 'post-1',
                  'status': 'publishing',
                  'retry_count': 1,
                  'progress': 30,
                },
              },
            );
          },
          getHandler: (path) async {
            calls.add('GET $path');
            if (path.endsWith('/job-1')) {
              return Response<dynamic>(
                requestOptions: RequestOptions(path: path),
                statusCode: 200,
                data: <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'id': 'job-1',
                    'post_id': 'post-1',
                    'status': 'published',
                    'retry_count': 1,
                    'progress': 100,
                  },
                },
              );
            }
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 200,
              data: <String, dynamic>{
                'success': true,
                'data': <dynamic>[
                  <String, dynamic>{
                    'id': 'job-1',
                    'post_id': 'post-1',
                    'status': 'retrying',
                    'retry_count': 1,
                    'progress': 55,
                  },
                ],
              },
            );
          },
          deleteHandler: (path, data) async {
            calls.add('DELETE $path');
            return Response<dynamic>(
              requestOptions: RequestOptions(path: path),
              statusCode: 204,
              data: null,
            );
          },
        );

        final repo = LaravelPublishRepository(networkClient: client);

        final created = await repo.createPublishJob(
          const job.PublishJobEntity(id: 'job-1', postId: 'post-1'),
        );
        expect(created.isSuccess, isTrue);

        final updated = await repo.updatePublishJob(
          const job.PublishJobEntity(
            id: 'job-1',
            postId: 'post-1',
            status: job.PublishStatus.publishing,
            progress: 30,
            retryCount: 1,
          ),
        );
        expect(updated.isSuccess, isTrue);

        final listed = await repo.getJobs();
        expect(listed.isSuccess, isTrue);
        expect(listed.data, isNotEmpty);

        final loaded = await repo.getJob('job-1');
        expect(loaded.isSuccess, isTrue);
        expect(loaded.data?.status, job.PublishStatus.published);

        final deleted = await repo.deleteJob('job-1');
        expect(deleted.isSuccess, isTrue);

        expect(calls, contains('POST /api/v1/publish/jobs'));
        expect(calls, contains('PATCH /api/v1/publish/jobs/job-1'));
        expect(calls, contains('GET /api/v1/publish/jobs'));
        expect(calls, contains('GET /api/v1/publish/jobs/job-1'));
        expect(calls, contains('DELETE /api/v1/publish/jobs/job-1'));
      },
    );
  });
}
