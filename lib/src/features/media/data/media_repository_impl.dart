import 'package:dio/dio.dart' show FormData, MultipartFile;

import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/backend_contract_mapper_v1.dart';
import '../../../backend_contracts/v1/media_contract_v1.dart';
import '../../../media_engine/core/media_engine_exception.dart';
import '../../../media_engine/media_engine.dart';
import '../../../media_engine/upload/upload_manager.dart';
import '../../../offline/queue/outbox_entry.dart';
import '../../../offline/queue/outbox_store.dart';
import '../../../offline/sync/resumable_upload_manager.dart';
import '../../../core/events/event_dispatcher.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/app_result.dart';
import '../../posts/domain/entities/media_entity.dart';
import '../events/media_uploaded_event.dart';
import '../domain/repositories/media_repository.dart';

class MediaRepositoryImpl extends MediaRepository {
  MediaRepositoryImpl({
    this.networkClient,
    this.eventDispatcher,
    this.mediaEngine = const MediaEngine(),
    UploadManager? uploadManager,
    OutboxStore? outboxStore,
    ResumableUploadManager? resumableUploadManager,
  }) : uploadManager = uploadManager ?? UploadManager(),
       outboxStore = outboxStore ?? OutboxStore(),
       resumableUploadManager =
           resumableUploadManager ?? ResumableUploadManager();

  final NetworkClient? networkClient;
  final EventDispatcher? eventDispatcher;
  final MediaEngine mediaEngine;
  final UploadManager uploadManager;
  final OutboxStore outboxStore;
  final ResumableUploadManager resumableUploadManager;
  final Map<String, MediaEntity> _inMemoryStore = <String, MediaEntity>{};

  @override
  Future<AppResult<MediaEntity>> uploadMedia(MediaEntity media) async {
    late final MediaEntity preparedMedia;
    try {
      preparedMedia = mediaEngine.prepareForUpload(media).media;
    } on MediaEngineException catch (error) {
      return Failure<MediaEntity>.fromFailure(
        ValidationFailure(message: error.message, code: error.code),
      );
    }

    uploadManager.start(
      mediaId: preparedMedia.id,
      totalBytes: preparedMedia.sizeInBytes,
    );

    if (networkClient != null) {
      try {
        final request = BackendContractMapperV1.toMediaUploadRequest(
          preparedMedia,
        );

        final isRemoteUrl = _isRemoteUrl(preparedMedia.url);
        final payload = <String, dynamic>{...request.toJson()};
        if (!isRemoteUrl) {
          final multipartFile = await MultipartFile.fromFile(
            preparedMedia.url,
            filename: request.fileName,
          );
          payload['file'] = multipartFile;
        }

        final response = await networkClient!.upload(
          LaravelEndpoints.mediaUpload,
          formData: FormData.fromMap(payload),
        );

        final data = _unwrapPayload(response.data) as Map<String, dynamic>;
        final uploadedMedia = _fromResponse(data);
        uploadManager.update(
          mediaId: preparedMedia.id,
          uploadedBytes: preparedMedia.sizeInBytes,
        );
        uploadManager.complete(preparedMedia.id);
        await resumableUploadManager.complete(preparedMedia.id);
        await eventDispatcher?.dispatch(
          MediaUploadedEvent(
            mediaId: uploadedMedia.id,
            postId: uploadedMedia.postId,
          ),
        );
        return Success<MediaEntity>(
          uploadedMedia,
          message: 'Media uploaded remotely',
        );
      } catch (error, stackTrace) {
        final failure = mapFailure(
          error,
          stackTrace,
          fallbackMessage: 'Failed to upload media',
        );
        if (failure is NetworkFailure) {
          await _enqueueMediaOperation(
            OutboxOperation.uploadMedia,
            preparedMedia,
          );
          await resumableUploadManager.startSession(
            UploadSession(
              mediaId: preparedMedia.id,
              filePath: preparedMedia.url,
              totalBytes: preparedMedia.sizeInBytes,
              uploadedBytes: 0,
            ),
          );
          _inMemoryStore[preparedMedia.id] = preparedMedia;
          return Success<MediaEntity>(
            preparedMedia,
            message: 'Media upload queued for sync',
          );
        }
        uploadManager.complete(preparedMedia.id);
        return Failure<MediaEntity>.fromFailure(failure);
      }
    }

    return executeTransaction(
      () async {
        _inMemoryStore[preparedMedia.id] = preparedMedia;
        await _enqueueMediaOperation(
          OutboxOperation.uploadMedia,
          preparedMedia,
        );
        await resumableUploadManager.startSession(
          UploadSession(
            mediaId: preparedMedia.id,
            filePath: preparedMedia.url,
            totalBytes: preparedMedia.sizeInBytes,
            uploadedBytes: 0,
          ),
        );
        uploadManager.update(
          mediaId: preparedMedia.id,
          uploadedBytes: preparedMedia.sizeInBytes,
        );
        uploadManager.complete(preparedMedia.id);
        await eventDispatcher?.dispatch(
          MediaUploadedEvent(
            mediaId: preparedMedia.id,
            postId: preparedMedia.postId,
          ),
        );
        return preparedMedia;
      },
      operation: 'media.upload.local',
      fallbackMessage: 'Failed to upload media locally',
    );
  }

  @override
  Future<AppResult<MediaEntity>> compressMedia(MediaEntity media) async {
    late final MediaEntity processedMedia;
    try {
      processedMedia = mediaEngine.compress(media).media;
    } on MediaEngineException catch (error) {
      return Failure<MediaEntity>.fromFailure(
        ValidationFailure(message: error.message, code: error.code),
      );
    }

    if (networkClient != null) {
      try {
        final request = BackendContractMapperV1.toMediaCompressRequest(
          processedMedia,
        );
        final response = await networkClient!.post(
          LaravelEndpoints.mediaCompress,
          data: request.toJson(),
        );
        final data = _unwrapPayload(response.data) as Map<String, dynamic>;
        return Success<MediaEntity>(
          _fromResponse(data),
          message: 'Media compressed remotely',
        );
      } catch (error, stackTrace) {
        final failure = mapFailure(
          error,
          stackTrace,
          fallbackMessage: 'Failed to compress media',
        );
        if (failure is NetworkFailure) {
          final compressedOffline = processedMedia;
          _inMemoryStore[compressedOffline.id] = compressedOffline;
          await _enqueueMediaOperation(
            OutboxOperation.compressMedia,
            compressedOffline,
          );
          return Success<MediaEntity>(
            compressedOffline,
            message: 'Media compress queued for sync',
          );
        }
        return Failure<MediaEntity>.fromFailure(failure);
      }
    }

    final compressed = processedMedia;
    return executeTransaction(
      () async {
        _inMemoryStore[compressed.id] = compressed;
        await _enqueueMediaOperation(OutboxOperation.compressMedia, compressed);
        return compressed;
      },
      operation: 'media.compress.local',
      fallbackMessage: 'Failed to compress media locally',
    );
  }

  @override
  Future<AppResult<void>> deleteMedia(String id) async {
    if (networkClient != null) {
      try {
        await networkClient!.delete(LaravelEndpoints.mediaById(id));
        return const Success<void>(null, message: 'Media deleted remotely');
      } catch (error, stackTrace) {
        final failure = mapFailure(
          error,
          stackTrace,
          fallbackMessage: 'Failed to delete media',
        );
        if (failure is NetworkFailure) {
          await _enqueueDeleteOperation(id);
          return const Success<void>(
            null,
            message: 'Media delete queued for sync',
          );
        }
        return Failure<void>.fromFailure(failure);
      }
    }

    return executeTransaction<void>(
      () async {
        _inMemoryStore.remove(id);
        await resumableUploadManager.complete(id);
        await _enqueueDeleteOperation(id);
      },
      operation: 'media.delete.local',
      fallbackMessage: 'Failed to delete media locally',
    );
  }

  Future<void> _enqueueMediaOperation(
    OutboxOperation operation,
    MediaEntity media,
  ) {
    return outboxStore.enqueue(
      OutboxEntry(
        id: '${operation.name}:${media.id}:${DateTime.now().microsecondsSinceEpoch}',
        operation: operation,
        payload: <String, dynamic>{
          'id': media.id,
          'post_id': media.postId,
          'url': media.url,
          'mime_type': media.mimeType,
          'size_in_bytes': media.sizeInBytes,
          'is_compressed': media.isCompressed,
        },
        resumeToken: operation == OutboxOperation.uploadMedia ? media.id : null,
      ),
    );
  }

  Future<void> _enqueueDeleteOperation(String mediaId) {
    return outboxStore.enqueue(
      OutboxEntry(
        id: 'deleteMedia:$mediaId:${DateTime.now().microsecondsSinceEpoch}',
        operation: OutboxOperation.deleteMedia,
        payload: <String, dynamic>{'id': mediaId},
      ),
    );
  }

  MediaEntity _fromResponse(Map<String, dynamic> data) {
    final dto = MediaResponseDtoV1.fromJson(data);
    return BackendContractMapperV1.toMediaEntity(dto);
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }

  bool _isRemoteUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }
}
