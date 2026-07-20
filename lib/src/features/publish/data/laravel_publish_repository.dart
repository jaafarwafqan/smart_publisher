import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/backend_contract_mapper_v1.dart';
import '../../../backend_contracts/v1/publish_contract_v1.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../domain/entities/publish_job_entity.dart';
import '../domain/repositories/publish_repository.dart';

class LaravelPublishRepository extends PublishRepository {
  LaravelPublishRepository({this.networkClient});

  final NetworkClient? networkClient;
  final Map<String, PublishJobEntity> _inMemoryStore =
      <String, PublishJobEntity>{};

  @override
  Future<AppResult<PublishJobEntity>> createPublishJob(
    PublishJobEntity job,
  ) async {
    if (networkClient == null) {
      _inMemoryStore[job.id] = job;
      return Success<PublishJobEntity>(
        job,
        message: 'Publish job created locally',
      );
    }

    return execute(
      () async {
        final request = PublishJobRequestDtoV1(postId: job.postId);
        final response = await networkClient!.post(
          LaravelEndpoints.publishJobs,
          data: request.toJson(),
        );
        return _fromResponse(response.data);
      },
      operation: 'publish.jobs.create.remote',
      fallbackMessage: 'Failed to create publish job',
    );
  }

  @override
  Future<AppResult<PublishJobEntity>> updatePublishJob(
    PublishJobEntity job,
  ) async {
    if (networkClient == null) {
      _inMemoryStore[job.id] = job;
      return Success<PublishJobEntity>(
        job,
        message: 'Publish job updated locally',
      );
    }

    return execute(
      () async {
        final request = PublishJobUpdateRequestDtoV1(
          status: job.status.name,
          progress: job.progress,
        );
        final response = await networkClient!.patch(
          LaravelEndpoints.publishJobById(job.id),
          data: request.toJson(),
        );
        return _fromResponse(response.data);
      },
      operation: 'publish.jobs.update.remote',
      fallbackMessage: 'Failed to update publish job',
    );
  }

  @override
  Future<AppResult<List<PublishJobEntity>>> getJobs() async {
    if (networkClient == null) {
      return Success<List<PublishJobEntity>>(
        _inMemoryStore.values.toList(growable: false),
        message: 'Publish jobs listed locally',
      );
    }

    return executeList(
      () async {
        final response = await networkClient!.get(LaravelEndpoints.publishJobs);
        final payload = _unwrapPayload(response.data);
        final items = payload is List<dynamic>
            ? payload
            : (payload is Map<String, dynamic> && payload['items'] is List)
            ? payload['items'] as List<dynamic>
            : <dynamic>[];
        return items
            .whereType<Map<String, dynamic>>()
            .map(
              (json) => BackendContractMapperV1.toPublishJobEntity(
                PublishJobResponseDtoV1.fromJson(json),
              ),
            )
            .toList(growable: false);
      },
      operation: 'publish.jobs.list.remote',
      fallbackMessage: 'Failed to list publish jobs',
    );
  }

  Future<AppResult<PublishJobEntity>> getJob(String id) async {
    if (networkClient == null) {
      final job = _inMemoryStore[id];
      if (job == null) {
        return Failure<PublishJobEntity>.fromFailure(
          const ValidationFailure(message: 'Publish job not found'),
        );
      }
      return Success<PublishJobEntity>(
        job,
        message: 'Publish job loaded locally',
      );
    }

    return execute(
      () async {
        final response = await networkClient!.get(
          LaravelEndpoints.publishJobById(id),
        );
        return _fromResponse(response.data);
      },
      operation: 'publish.jobs.get.remote',
      fallbackMessage: 'Failed to get publish job',
    );
  }

  @override
  Future<AppResult<void>> deleteJob(String id) async {
    if (networkClient == null) {
      _inMemoryStore.remove(id);
      return const Success<void>(null, message: 'Publish job deleted locally');
    }

    return execute(
      () async {
        await networkClient!.delete(LaravelEndpoints.publishJobById(id));
      },
      operation: 'publish.jobs.delete.remote',
      fallbackMessage: 'Failed to delete publish job',
    );
  }

  PublishJobEntity _fromResponse(dynamic raw) {
    final payload = _unwrapPayload(raw);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Invalid publish response payload');
    }
    final dto = PublishJobResponseDtoV1.fromJson(payload);
    return BackendContractMapperV1.toPublishJobEntity(dto);
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }
}
