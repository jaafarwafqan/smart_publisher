import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/dashboard/presentation/utils/dashboard_post_filters.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';

PostEntity _post({
  required String id,
  String status = 'draft',
  DateTime? scheduledAt,
  DateTime? publishedAt,
  DateTime? updatedAt,
  List<String> platforms = const <String>[],
}) {
  return PostEntity(
    id: id,
    title: 'Post $id',
    body: 'body',
    status: status,
    scheduledAt: scheduledAt,
    publishedAt: publishedAt,
    updatedAt: updatedAt,
    platforms: platforms,
  );
}

void main() {
  final now = DateTime(2026, 6, 15, 12);

  group('scheduledToday', () {
    test('includes a post scheduled later today (23:59)', () {
      final post = _post(
        id: '1',
        status: 'scheduled',
        scheduledAt: DateTime(2026, 6, 15, 23, 59),
      );
      expect(scheduledToday(<PostEntity>[post], now), <PostEntity>[post]);
    });

    test('excludes a post scheduled for tomorrow (00:01)', () {
      final post = _post(
        id: '1',
        status: 'scheduled',
        scheduledAt: DateTime(2026, 6, 16, 0, 1),
      );
      expect(scheduledToday(<PostEntity>[post], now), isEmpty);
    });

    test('excludes non-scheduled posts even if scheduledAt is today', () {
      final post = _post(
        id: '1',
        status: 'published',
        scheduledAt: DateTime(2026, 6, 15, 8),
      );
      expect(scheduledToday(<PostEntity>[post], now), isEmpty);
    });
  });

  group('publishingQueue', () {
    test('includes scheduled and publishing posts, soonest first', () {
      final later = _post(
        id: 'later',
        status: 'scheduled',
        scheduledAt: DateTime(2026, 6, 20),
      );
      final sooner = _post(
        id: 'sooner',
        status: 'publishing',
        scheduledAt: DateTime(2026, 6, 16),
      );
      final draft = _post(id: 'draft', status: 'draft');

      final result = publishingQueue(<PostEntity>[later, sooner, draft]);

      expect(result, <PostEntity>[sooner, later]);
    });
  });

  group('failedPosts', () {
    test('only includes failed status', () {
      final failed = _post(id: '1', status: 'failed');
      final published = _post(id: '2', status: 'published');
      expect(failedPosts(<PostEntity>[failed, published]), <PostEntity>[
        failed,
      ]);
    });
  });

  group('lastPublished', () {
    test('sorts by publishedAt descending', () {
      final older = _post(
        id: 'older',
        status: 'published',
        publishedAt: DateTime(2026, 6, 1),
      );
      final newer = _post(
        id: 'newer',
        status: 'published',
        publishedAt: DateTime(2026, 6, 10),
      );

      final result = lastPublished(<PostEntity>[older, newer]);

      expect(result, <PostEntity>[newer, older]);
    });

    test('falls back to updatedAt when publishedAt is null', () {
      final post = _post(
        id: '1',
        status: 'published',
        updatedAt: DateTime(2026, 6, 5),
      );
      final result = lastPublished(<PostEntity>[post]);
      expect(result, <PostEntity>[post]);
    });

    test('respects the take limit', () {
      final posts = List<PostEntity>.generate(
        10,
        (i) => _post(
          id: '$i',
          status: 'published',
          publishedAt: DateTime(2026, 6, i + 1),
        ),
      );
      expect(lastPublished(posts, take: 3), hasLength(3));
    });
  });

  group('upcomingSchedule', () {
    test('excludes past-dated scheduled posts', () {
      final past = _post(
        id: 'past',
        status: 'scheduled',
        scheduledAt: DateTime(2026, 6, 1),
      );
      final future = _post(
        id: 'future',
        status: 'scheduled',
        scheduledAt: DateTime(2026, 7, 1),
      );

      final result = upcomingSchedule(<PostEntity>[past, future], now);

      expect(result, <PostEntity>[future]);
    });

    test('sorts soonest first', () {
      final later = _post(
        id: 'later',
        status: 'scheduled',
        scheduledAt: DateTime(2026, 8, 1),
      );
      final sooner = _post(
        id: 'sooner',
        status: 'scheduled',
        scheduledAt: DateTime(2026, 7, 1),
      );

      final result = upcomingSchedule(<PostEntity>[later, sooner], now);

      expect(result, <PostEntity>[sooner, later]);
    });
  });

  group('platformDistribution', () {
    test(
      'tallies platform occurrences across all posts regardless of status',
      () {
        final posts = <PostEntity>[
          _post(id: '1', platforms: <String>['facebook', 'instagram']),
          _post(id: '2', platforms: <String>['facebook']),
          _post(id: '3', platforms: <String>['x']),
        ];

        final result = platformDistribution(posts);

        expect(result, <String, int>{'facebook': 2, 'instagram': 1, 'x': 1});
      },
    );
  });
}
