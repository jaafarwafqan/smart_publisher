import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/backend_contract_mapper_v1.dart';
import '../../../backend_contracts/v1/calendar_contract_v1.dart';
import '../../../backend_contracts/v1/posts_contract_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../../posts/domain/entities/post_entity.dart';
import '../domain/entities/schedule_entity.dart';
import '../domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl extends ScheduleRepository {
  ScheduleRepositoryImpl({required this.networkClient});

  final NetworkClient networkClient;

  @override
  Future<AppResult<PostEntity>> schedulePost(PostEntity post) async {
    final scheduledAt = post.scheduledAt;
    if (scheduledAt == null) {
      return Failure<PostEntity>('A schedule date/time is required.');
    }

    try {
      final response = await networkClient.post(
        LaravelEndpoints.postSchedule(post.id),
        data: ScheduleRequestDtoV1(scheduledAt: scheduledAt).toJson(),
      );
      final scheduledPost = _parsePostResponse(response.data);

      // A 202 here means the acting user's organization role doesn't hold
      // posts.publish (e.g. editor) — the request was held for
      // manager/admin/owner approval rather than scheduled immediately
      // (scheduledPost.status stays 'draft' in that case, not 'scheduled').
      // Surface the backend's real message instead of a fixed string that
      // would claim success even when it was only submitted for review.
      final raw = response.data;
      final message = raw is Map<String, dynamic>
          ? raw['message'] as String?
          : null;

      return Success<PostEntity>(
        scheduledPost,
        message: message ?? 'Post scheduled remotely',
      );
    } catch (error, stackTrace) {
      return Failure<PostEntity>.fromFailure(
        mapFailure(
          error,
          stackTrace,
          fallbackMessage: 'Failed to schedule post',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> cancelSchedule(String postId) async {
    try {
      await networkClient.post(LaravelEndpoints.postDraft(postId));
      return const Success<void>(null, message: 'Schedule cancelled');
    } catch (error, stackTrace) {
      return Failure<void>.fromFailure(
        mapFailure(
          error,
          stackTrace,
          fallbackMessage: 'Failed to cancel schedule',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ScheduleEntity>>> getCalendarEntries() async {
    try {
      final response = await networkClient.get(LaravelEndpoints.calendar);
      final payload = _unwrapPayload(response.data);
      final rawItems =
          payload is Map<String, dynamic> && payload['items'] is List<dynamic>
          ? payload['items'] as List<dynamic>
          : <dynamic>[];

      final entries = rawItems
          .whereType<Map<String, dynamic>>()
          .map(CalendarEntryResponseDtoV1.fromJson)
          .where((entry) => entry.scheduledAt != null)
          .map(
            (entry) => ScheduleEntity(
              id: entry.postId,
              postId: entry.postId,
              title: entry.title,
              status: entry.status,
              scheduledAt: entry.scheduledAt!,
            ),
          )
          .toList(growable: false);

      return Success<List<ScheduleEntity>>(
        entries,
        message: 'Calendar entries retrieved',
      );
    } catch (error, stackTrace) {
      return Failure<List<ScheduleEntity>>.fromFailure(
        mapFailure(
          error,
          stackTrace,
          fallbackMessage: 'Failed to load calendar entries',
        ),
      );
    }
  }

  PostEntity _parsePostResponse(dynamic responseData) {
    final payload = _unwrapPayload(responseData);
    if (payload is! Map<String, dynamic>) {
      throw StateError('Invalid post response payload');
    }
    final dto = PostResponseDtoV1.fromJson(payload);
    return BackendContractMapperV1.toPostEntity(dto);
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }
}
