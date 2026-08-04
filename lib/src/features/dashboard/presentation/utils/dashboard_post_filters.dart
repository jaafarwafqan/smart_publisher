import '../../../posts/domain/entities/post_entity.dart';

/// Posts scheduled for later today.
List<PostEntity> scheduledToday(List<PostEntity> posts, DateTime now) {
  return posts
      .where(
        (post) =>
            post.status == 'scheduled' &&
            post.scheduledAt != null &&
            _isSameDay(post.scheduledAt!, now),
      )
      .toList(growable: false);
}

/// Everything about to be dispatched or currently being dispatched,
/// soonest-scheduled first.
List<PostEntity> publishingQueue(List<PostEntity> posts) {
  final items =
      posts
          .where(
            (post) => post.status == 'scheduled' || post.status == 'publishing',
          )
          .toList()
        ..sort(
          (a, b) => (a.scheduledAt ?? DateTime(9999)).compareTo(
            b.scheduledAt ?? DateTime(9999),
          ),
        );
  return items;
}

List<PostEntity> failedPosts(List<PostEntity> posts) {
  return posts.where((post) => post.status == 'failed').toList(growable: false);
}

/// Most recently published posts, newest first. Falls back to [updatedAt]
/// when [PostEntity.publishedAt] hasn't made it through yet for a given
/// post (e.g. older records fetched before the field existed).
List<PostEntity> lastPublished(List<PostEntity> posts, {int take = 5}) {
  final items = posts.where((post) => post.status == 'published').toList()
    ..sort((a, b) => _publishedKey(b).compareTo(_publishedKey(a)));
  return items.take(take).toList(growable: false);
}

/// Future-dated scheduled posts, soonest first. Past-dated "scheduled"
/// posts (which should have already been picked up by the scheduler) are
/// deliberately excluded here — those belong in [publishingQueue] as
/// something to watch, not "upcoming".
List<PostEntity> upcomingSchedule(
  List<PostEntity> posts,
  DateTime now, {
  int take = 5,
}) {
  final items =
      posts
          .where(
            (post) =>
                post.status == 'scheduled' &&
                post.scheduledAt != null &&
                post.scheduledAt!.isAfter(now),
          )
          .toList()
        ..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
  return items.take(take).toList(growable: false);
}

/// How many posts target each platform, across every post regardless of
/// status — used for the Publishing Health distribution chart.
Map<String, int> platformDistribution(List<PostEntity> posts) {
  final counts = <String, int>{};
  for (final post in posts) {
    for (final platform in post.platforms) {
      counts[platform] = (counts[platform] ?? 0) + 1;
    }
  }
  return counts;
}

DateTime _publishedKey(PostEntity post) =>
    post.publishedAt ?? post.updatedAt ?? DateTime(0);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
