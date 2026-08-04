import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/schedule/data/schedule_repository_impl.dart';

import '../../helpers/fake_network_client.dart';

Response<dynamic> _jsonResponse(String path, Map<String, dynamic> data) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    data: data,
    statusCode: 200,
  );
}

void main() {
  group('ScheduleRepositoryImpl', () {
    test(
      'schedulePost posts to /posts/{id}/schedule with scheduled_at',
      () async {
        String? capturedPath;
        Map<String, dynamic>? capturedBody;

        final repo = ScheduleRepositoryImpl(
          networkClient: FakeNetworkClient(
            postHandler: (path, data) async {
              capturedPath = path;
              capturedBody = data as Map<String, dynamic>;
              return _jsonResponse(path, <String, dynamic>{
                'id': 'p1',
                'title': 'Hello',
                'content': 'World',
                'status': 'scheduled',
                'scheduled_at': '2026-08-01T10:00:00.000Z',
              });
            },
          ),
        );

        final scheduledAt = DateTime.utc(2026, 8, 1, 10);
        final result = await repo.schedulePost(
          PostEntity(
            id: 'p1',
            title: 'Hello',
            body: 'World',
            scheduledAt: scheduledAt,
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(capturedPath, contains('/posts/p1/schedule'));
        expect(capturedBody?['scheduled_at'], scheduledAt.toIso8601String());
        expect(result.data?.status, 'scheduled');
      },
    );

    test('schedulePost fails fast without a scheduledAt', () async {
      final repo = ScheduleRepositoryImpl(networkClient: FakeNetworkClient());

      final result = await repo.schedulePost(
        const PostEntity(id: 'p1', title: 'Hello', body: 'World'),
      );

      expect(result.isFailure, isTrue);
    });

    test('cancelSchedule posts to /posts/{id}/draft', () async {
      String? capturedPath;

      final repo = ScheduleRepositoryImpl(
        networkClient: FakeNetworkClient(
          postHandler: (path, data) async {
            capturedPath = path;
            return _jsonResponse(path, <String, dynamic>{});
          },
        ),
      );

      final result = await repo.cancelSchedule('p1');

      expect(result.isSuccess, isTrue);
      expect(capturedPath, contains('/posts/p1/draft'));
    });

    test('getCalendarEntries parses the {items: [...]} shape', () async {
      final repo = ScheduleRepositoryImpl(
        networkClient: FakeNetworkClient(
          getHandler: (path) async {
            return _jsonResponse(path, <String, dynamic>{
              'items': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'event-1',
                  'post_id': '1',
                  'title': 'Launch post',
                  'status': 'scheduled',
                  'scheduled_at': '2026-08-01T10:00:00.000Z',
                },
              ],
            });
          },
        ),
      );

      final result = await repo.getCalendarEntries();

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      expect(result.data!.single.postId, '1');
      expect(result.data!.single.title, 'Launch post');
      expect(result.data!.single.status, 'scheduled');
    });
  });
}
