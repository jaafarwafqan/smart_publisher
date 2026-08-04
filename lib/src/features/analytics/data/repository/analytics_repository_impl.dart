import '../../../../backend_contracts/v1/analytics_contract_v1.dart';
import '../../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../../core/network/laravel_api.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/result/app_result.dart';
import '../../domain/entities/analytics_dashboard_entity.dart';
import '../../domain/entities/analytics_insight_entity.dart';
import '../../domain/entities/analytics_metric_entity.dart';
import '../../domain/entities/analytics_report_entity.dart';
import '../../domain/entities/analytics_summary_entity.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl extends AnalyticsRepository {
  AnalyticsRepositoryImpl({this.networkClient});

  final NetworkClient? networkClient;
  final Map<String, AnalyticsMetricEntity> _cache =
      <String, AnalyticsMetricEntity>{};

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }
    return fallback;
  }

  double _asDouble(Object? value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  @override
  Future<AppResult<AnalyticsMetricEntity>> getPostMetrics(String postId) async {
    if (networkClient != null) {
      return execute(
        () async {
          final response = await networkClient!.get(
            LaravelEndpoints.analyticsPostById(postId),
          );
          final payload = _unwrapPayload(response.data) as Map<String, dynamic>;
          final dto = PostAnalyticsResponseDtoV1.fromJson(payload);
          final metric = _toMetric(dto);
          _cache[metric.postId] = metric;
          return metric;
        },
        operation: 'analytics.metrics.remote',
        fallbackMessage: 'Failed to fetch analytics metrics',
      );
    }

    return execute(
      () async {
        final cached = _cache[postId];
        if (cached != null) {
          return cached;
        }

        final generated = AnalyticsMetricEntity(
          postId: postId,
          impressions: 0,
          clicks: 0,
          shares: 0,
          reactions: 0,
          comments: 0,
          reach: 0,
          engagement: 0,
          status: 'draft',
          available: false,
        );
        _cache[postId] = generated;
        return generated;
      },
      operation: 'analytics.metrics.local',
      fallbackMessage: 'Failed to build local analytics metrics',
    );
  }

  @override
  Future<AppResult<List<AnalyticsMetricEntity>>> getPostsMetrics(
    List<String> postIds,
  ) async {
    if (networkClient != null) {
      return executeList(
        () async {
          final response = await networkClient!.get(
            LaravelEndpoints.analyticsPostsBulk(postIds),
          );
          final payload = _unwrapPayload(response.data);
          final items = payload is List<dynamic> ? payload : <dynamic>[];

          final metrics = items
              .whereType<Map<String, dynamic>>()
              .map(PostAnalyticsResponseDtoV1.fromJson)
              .map(_toMetric)
              .toList(growable: false);

          for (final metric in metrics) {
            _cache[metric.postId] = metric;
          }

          return metrics;
        },
        operation: 'analytics.metrics.bulk.remote',
        fallbackMessage: 'Failed to fetch analytics metrics',
      );
    }

    return executeList(
      () async => postIds
          .map((id) => _cache[id] ?? _localMetric(id))
          .toList(growable: false),
      operation: 'analytics.metrics.bulk.local',
      fallbackMessage: 'Failed to build local analytics metrics',
    );
  }

  AnalyticsMetricEntity _localMetric(String postId) {
    return AnalyticsMetricEntity(
      postId: postId,
      impressions: 0,
      clicks: 0,
      shares: 0,
      reactions: 0,
      comments: 0,
      reach: 0,
      engagement: 0,
      status: 'draft',
      available: false,
    );
  }

  @override
  Future<AppResult<AnalyticsDashboardEntity>> getDashboard() {
    if (networkClient != null) {
      return execute(
        () async {
          final response = await networkClient!.get(
            LaravelEndpoints.analyticsDashboard,
          );
          final payload = _unwrapPayload(response.data);

          if (payload is! Map<String, dynamic>) {
            throw StateError('Invalid analytics dashboard response');
          }

          final rawTop = payload['top_posts'];
          final rawItems = rawTop is List<dynamic> ? rawTop : <dynamic>[];
          final topPosts = rawItems
              .whereType<Map<String, dynamic>>()
              .map(PostAnalyticsResponseDtoV1.fromJson)
              .map(_toMetric)
              .toList(growable: false);

          for (final metric in topPosts) {
            _cache[metric.postId] = metric;
          }

          final totalReach = _asInt(payload['total_reach']);
          final totalEngagement = _asInt(payload['total_engagement']);
          final totalImpressions = _asInt(payload['total_impressions']);
          final avgRate = _asDouble(payload['average_engagement_rate']);
          final bestPlatform = payload['best_platform'] as String?;
          final bestPublishHour = payload['best_publish_hour'] == null
              ? null
              : _asInt(payload['best_publish_hour']);

          return AnalyticsDashboardEntity(
            generatedAt: DateTime.now(),
            totalReach: totalReach,
            totalEngagement: totalEngagement,
            totalImpressions: totalImpressions,
            averageEngagementRate: avgRate,
            topPosts: topPosts,
            bestPlatform: bestPlatform,
            bestPublishHour: bestPublishHour,
          );
        },
        operation: 'analytics.dashboard.remote',
        fallbackMessage: 'Failed to fetch analytics dashboard',
      );
    }

    return execute(
      () async {
        final entries = _cache.values.toList(growable: false);
        final totalReach = entries.fold<int>(
          0,
          (sum, item) => sum + item.reach,
        );
        final totalEngagement = entries.fold<int>(
          0,
          (sum, item) => sum + item.engagement,
        );
        final totalImpressions = entries.fold<int>(
          0,
          (sum, item) => sum + item.impressions,
        );

        final averageRate = entries.isEmpty
            ? 0.0
            : entries.fold<double>(
                    0,
                    (sum, item) => sum + item.engagementRate,
                  ) /
                  entries.length;

        final topPosts = entries.toList()
          ..sort((a, b) => b.engagement.compareTo(a.engagement));

        return AnalyticsDashboardEntity(
          generatedAt: DateTime.now(),
          totalReach: totalReach,
          totalEngagement: totalEngagement,
          totalImpressions: totalImpressions,
          averageEngagementRate: averageRate,
          topPosts: topPosts.take(5).toList(growable: false),
        );
      },
      operation: 'analytics.dashboard',
      fallbackMessage: 'Failed to build analytics dashboard',
    );
  }

  @override
  Future<AppResult<AnalyticsSummaryEntity>> getSummary() {
    if (networkClient != null) {
      return execute(
        () async {
          final response = await networkClient!.get(
            LaravelEndpoints.analyticsSummary,
          );
          final payload = _unwrapPayload(response.data);

          if (payload is! Map<String, dynamic>) {
            throw StateError('Invalid analytics summary response');
          }

          final engagement =
              payload['engagement'] as Map<String, dynamic>? ??
              const <String, dynamic>{};

          return AnalyticsSummaryEntity(
            totalPosts: _asInt(payload['total_posts']),
            published: _asInt(payload['published']),
            failed: _asInt(payload['failed']),
            scheduled: _asInt(payload['scheduled']),
            draft: _asInt(payload['draft']),
            engagementScore: _asDouble(engagement['score']),
            engagementTrend: (engagement['trend'] as String?) ?? 'stable',
            updatedAt:
                DateTime.tryParse((payload['updated_at'] as String?) ?? '') ??
                DateTime.now(),
          );
        },
        operation: 'analytics.summary.remote',
        fallbackMessage: 'Failed to fetch analytics summary',
      );
    }

    return execute(
      () async => AnalyticsSummaryEntity(
        totalPosts: 0,
        published: 0,
        failed: 0,
        scheduled: 0,
        draft: 0,
        engagementScore: 0,
        engagementTrend: 'stable',
        updatedAt: DateTime.now(),
      ),
      operation: 'analytics.summary.local',
      fallbackMessage: 'Failed to build local analytics summary',
    );
  }

  @override
  Future<AppResult<List<AnalyticsInsightEntity>>> getInsights(String postId) {
    return executeList(
      () async {
        final metricResult = await getPostMetrics(postId);
        if (metricResult.isFailure || metricResult.data == null) {
          return <AnalyticsInsightEntity>[];
        }

        final metric = metricResult.data!;
        final insights = <AnalyticsInsightEntity>[];

        if (metric.engagementRate >= 0.1) {
          insights.add(
            AnalyticsInsightEntity(
              title: 'Strong Engagement',
              description: 'Post has strong engagement relative to reach.',
              type: AnalyticsInsightType.trend,
              value: metric.engagementRate,
            ),
          );
        } else {
          insights.add(
            AnalyticsInsightEntity(
              title: 'Improve CTA',
              description:
                  'Engagement is low; consider stronger call-to-action.',
              type: AnalyticsInsightType.recommendation,
              value: metric.engagementRate,
            ),
          );
        }

        if (metric.reach < 100) {
          insights.add(
            AnalyticsInsightEntity(
              title: 'Low Reach Alert',
              description: 'Reach is below expected threshold.',
              type: AnalyticsInsightType.alert,
              value: metric.reach,
            ),
          );
        }

        return insights;
      },
      operation: 'analytics.insights',
      fallbackMessage: 'Failed to generate analytics insights',
    );
  }

  @override
  Future<AppResult<AnalyticsReportEntity>> getReport({
    required DateTime from,
    required DateTime to,
    List<String> postIds = const <String>[],
  }) {
    return execute(
      () async {
        final reportItems = <AnalyticsMetricEntity>[];
        final ids = postIds.isEmpty
            ? _cache.keys.toList(growable: false)
            : postIds;

        for (final postId in ids) {
          final metricResult = await getPostMetrics(postId);
          if (metricResult.data != null) {
            reportItems.add(metricResult.data!);
          }
        }

        return AnalyticsReportEntity(
          id: 'report-${DateTime.now().microsecondsSinceEpoch}',
          from: from,
          to: to,
          items: reportItems,
          createdAt: DateTime.now(),
        );
      },
      operation: 'analytics.report',
      fallbackMessage: 'Failed to build analytics report',
    );
  }

  @override
  Future<AppResult<AnalyticsExportEntity>> exportReport(
    AnalyticsReportEntity report,
  ) {
    return execute(
      () async {
        final buffer = StringBuffer();
        buffer.writeln(
          'post_id,impressions,clicks,shares,reactions,reach,engagement,engagement_rate,status',
        );

        for (final item in report.items) {
          buffer.writeln(
            '${item.postId},${item.impressions},${item.clicks},${item.shares},${item.reactions},${item.reach},${item.engagement},${item.engagementRate.toStringAsFixed(4)},${item.status}',
          );
        }

        final fileName =
            'analytics-${report.from.toIso8601String()}-${report.to.toIso8601String()}.csv';

        return AnalyticsExportEntity(
          fileName: fileName,
          mimeType: 'text/csv',
          content: buffer.toString(),
        );
      },
      operation: 'analytics.export',
      fallbackMessage: 'Failed to export analytics report',
    );
  }

  AnalyticsMetricEntity _toMetric(PostAnalyticsResponseDtoV1 dto) {
    final engagement = dto.clicks + dto.shares + dto.reactions + dto.comments;
    return AnalyticsMetricEntity(
      postId: dto.postId,
      impressions: dto.impressions,
      clicks: dto.clicks,
      shares: dto.shares,
      reactions: dto.reactions,
      comments: dto.comments,
      reach: dto.reach,
      engagement: engagement,
      status: dto.status,
      available: dto.available,
    );
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }
}
