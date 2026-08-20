import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/app_providers.dart';
import '../../posts/domain/entities/post_entity.dart';
import '../domain/entities/analytics_dashboard_entity.dart';
import '../domain/entities/analytics_metric_entity.dart';

/// Pairs a post with its own aggregated metrics for the per-post analytics
/// list — was a private class inside analytics_screen.dart; moved here
/// (and made public) alongside the loading logic it's built by.
class PostAnalyticsViewModel {
  const PostAnalyticsViewModel({required this.post, required this.metric});

  final PostEntity post;
  final AnalyticsMetricEntity metric;
}

/// Code-quality review (2026-08-17), item B1/2.2: same `keepAlive` +
/// explicit-refresh-only pattern as [PostsListNotifier] — see that class's
/// docblock. [dashboardErrorMessage] is deliberately a field on otherwise-
/// successful data rather than something that fails the whole notifier:
/// the previous screen-local behavior showed the per-post rows even when
/// only the dashboard/summary call failed, and this preserves that exact
/// partial-success shape rather than blanking the whole screen for a
/// failure in one of two independent calls.
class AnalyticsScreenData {
  const AnalyticsScreenData({
    required this.rows,
    this.dashboard,
    this.dashboardErrorMessage,
  });

  final List<PostAnalyticsViewModel> rows;
  final AnalyticsDashboardEntity? dashboard;
  final String? dashboardErrorMessage;
}

class AnalyticsDashboardNotifier extends AsyncNotifier<AnalyticsScreenData> {
  @override
  Future<AnalyticsScreenData> build() => _load();

  Future<AnalyticsScreenData> _load() async {
    final repository = ref.read(analyticsRepositoryProvider);

    // Independent of the posts/metrics chain below — see
    // AnalyticsController::dashboard() on the backend, which computes its
    // own totals without any dependency on this screen's own post list.
    // Started here (a Future begins executing on creation, not on await)
    // so it runs concurrently instead of serially after the chain.
    final dashboardFuture = repository.getDashboard();

    final postsResult = await ref.read(postRepositoryProvider).getPosts();
    if (!postsResult.isSuccess) {
      throw StateError(postsResult.message ?? 'Failed to load analytics');
    }

    final posts = postsResult.data ?? const <PostEntity>[];
    final rows = <PostAnalyticsViewModel>[];

    if (posts.isNotEmpty) {
      final metricsResult = await repository.getPostsMetrics(
        posts.map((post) => post.id).toList(growable: false),
      );

      if (!metricsResult.isSuccess) {
        throw StateError(metricsResult.message ?? 'Failed to load analytics');
      }

      final metricsByPostId = <String, AnalyticsMetricEntity>{
        for (final metric
            in metricsResult.data ?? const <AnalyticsMetricEntity>[])
          metric.postId: metric,
      };

      for (final post in posts) {
        final metric = metricsByPostId[post.id];
        if (metric != null) {
          rows.add(PostAnalyticsViewModel(post: post, metric: metric));
        }
      }
    }

    rows.sort((a, b) => b.metric.engagement.compareTo(a.metric.engagement));

    final dashboardResult = await dashboardFuture;

    return AnalyticsScreenData(
      rows: rows,
      dashboard: dashboardResult.data,
      dashboardErrorMessage: dashboardResult.isFailure
          ? dashboardResult.message
          : null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue<AnalyticsScreenData>.loading().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(_load);
  }
}

final analyticsDashboardProvider =
    AsyncNotifierProvider<AnalyticsDashboardNotifier, AnalyticsScreenData>(
      AnalyticsDashboardNotifier.new,
    );
