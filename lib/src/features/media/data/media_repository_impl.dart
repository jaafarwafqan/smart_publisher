import 'dart:convert';

import 'package:dio/dio.dart' show FormData, MultipartFile, Options;

import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/backend_contract_mapper_v1.dart';
import '../../../backend_contracts/v1/media_contract_v1.dart';
import '../../../core/tenancy/active_organization_store.dart';
import '../../../media_engine/core/media_engine_exception.dart';
import '../../../media_engine/media_engine.dart';
import '../../../media_engine/upload/upload_manager.dart';
import '../../../offline/queue/outbox_entry.dart';
import '../../../offline/queue/outbox_store.dart';
import '../../../offline/sync/resumable_upload_manager.dart';
import '../../../core/events/event_dispatcher.dart';
import '../../../core/base/pagination.dart';
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
    this.activeOrganizationStore,
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
  // Nullable so tests/callers that never queue offline work aren't forced to
  // wire it up; when absent, newly-queued entries just get organizationId:
  // null (replay is never blocked, matching pre-fix behavior for that case,
  // same convention as PostRepositoryImpl).
  final ActiveOrganizationStore? activeOrganizationStore;
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
        if (preparedMedia.bytes != null) {
          // Flutter Web has no filesystem to read a path from — file_picker
          // can only supply raw bytes there, so upload those directly instead
          // of MultipartFile.fromFile (which requires dart:io and a real path).
          payload['file'] = MultipartFile.fromBytes(
            preparedMedia.bytes!,
            filename: request.fileName,
          );
        } else if (!isRemoteUrl) {
          final multipartFile = await MultipartFile.fromFile(
            preparedMedia.url,
            filename: request.fileName,
          );
          payload['file'] = multipartFile;
        }

        final response = await networkClient!.upload(
          LaravelEndpoints.mediaUpload,
          formData: FormData.fromMap(payload),
          // preparedMedia.id is a stable, client-generated local id that
          // never changes across a retry or an offline-outbox replay of
          // this exact upload attempt — sending it as the Idempotency-Key
          // means a lost response after the server already stored the file
          // (upload()'s own auto-retry below, or NetworkFailure re-queuing
          // this same media) returns the original attachment instead of
          // storing the file a second time. See
          // MediaLibraryController::store()'s idempotency check.
          options: Options(headers: {'Idempotency-Key': preparedMedia.id}),
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
        final response = await networkClient!.post(
          LaravelEndpoints.mediaCompress(processedMedia.id),
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

  @override
  Future<AppResult<List<MediaEntity>>> getMediaLibrary({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
  }) async {
    if (networkClient == null) {
      return executeList(
        () async => _inMemoryStore.values.toList(growable: false),
        operation: 'media.library.local',
        fallbackMessage: 'Failed to list local media',
      );
    }

    return executeList(
      () async {
        final queryParts = <String>[
          if (collection != null && collection.isNotEmpty)
            'collection=${Uri.encodeQueryComponent(collection)}',
          if (type != null && type.isNotEmpty)
            'type=${Uri.encodeQueryComponent(type)}',
          if (search != null && search.isNotEmpty)
            'search=${Uri.encodeQueryComponent(search)}',
          if (tags != null)
            for (final tag in tags) 'tags[]=${Uri.encodeQueryComponent(tag)}',
        ];
        final path = queryParts.isEmpty
            ? LaravelEndpoints.mediaUpload
            : '${LaravelEndpoints.mediaUpload}?${queryParts.join('&')}';

        final response = await networkClient!.get(path);
        final payload = _unwrapPayload(response.data);
        final items = payload is List<dynamic> ? payload : <dynamic>[];

        return items
            .whereType<Map<String, dynamic>>()
            .map(MediaResponseDtoV1.fromJson)
            .map(BackendContractMapperV1.toMediaEntity)
            .toList(growable: false);
      },
      operation: 'media.library.remote',
      fallbackMessage: 'Failed to load media library',
    );
  }

  @override
  Future<AppResult<PaginatedResult<MediaEntity>>> getMediaLibraryPage({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
    int page = 1,
  }) async {
    if (networkClient == null) {
      final all = _inMemoryStore.values.toList(growable: false);
      return Success<PaginatedResult<MediaEntity>>(
        PaginatedResult<MediaEntity>(
          items: all,
          page: 1,
          pageSize: all.length,
          totalCount: all.length,
        ),
      );
    }

    try {
      final queryParts = <String>[
        'page=$page',
        if (collection != null && collection.isNotEmpty)
          'collection=${Uri.encodeQueryComponent(collection)}',
        if (type != null && type.isNotEmpty)
          'type=${Uri.encodeQueryComponent(type)}',
        if (search != null && search.isNotEmpty)
          'search=${Uri.encodeQueryComponent(search)}',
        if (tags != null)
          for (final tag in tags) 'tags[]=${Uri.encodeQueryComponent(tag)}',
      ];
      final path = '${LaravelEndpoints.mediaUpload}?${queryParts.join('&')}';

      final response = await networkClient!.get(path);
      final raw = response.data;
      final payload = _unwrapPayload(raw);
      final rawItems = payload is List<dynamic> ? payload : <dynamic>[];
      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(MediaResponseDtoV1.fromJson)
          .map(BackendContractMapperV1.toMediaEntity)
          .toList(growable: false);

      // Same as posts: the pagination envelope lives as a sibling of
      // `data`, not inside it — ApiEnvelopeMiddleware preserves the
      // controller's `meta` object either way.
      final rawMeta = raw is Map<String, dynamic> ? raw['meta'] : null;
      final meta = rawMeta is Map<String, dynamic>
          ? rawMeta
          : const <String, dynamic>{};
      final currentPage = (meta['current_page'] as num?)?.toInt() ?? page;
      final perPage = (meta['per_page'] as num?)?.toInt() ?? items.length;
      final total = (meta['total'] as num?)?.toInt() ?? items.length;

      return Success<PaginatedResult<MediaEntity>>(
        PaginatedResult<MediaEntity>(
          items: items,
          page: currentPage,
          pageSize: perPage,
          totalCount: total,
        ),
        message: 'Media library page retrieved remotely',
      );
    } catch (error, stackTrace) {
      return Failure<PaginatedResult<MediaEntity>>.fromFailure(
        mapFailure(
          error,
          stackTrace,
          fallbackMessage: 'Failed to load media library',
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> attachMediaToPost({
    required String mediaId,
    required String postId,
  }) async {
    if (networkClient == null) {
      return const Failure<void>(
        'Reusing media in another post requires a connection.',
      );
    }

    return execute<void>(
      () async {
        await networkClient!.post(
          LaravelEndpoints.postMediaAttach(postId),
          data: <String, dynamic>{
            'attachment_ids': <int>[int.parse(mediaId)],
          },
        );
      },
      operation: 'media.attach_to_post',
      fallbackMessage: 'Failed to reuse media in the post',
    );
  }

  Future<void> _enqueueMediaOperation(
    OutboxOperation operation,
    MediaEntity media,
  ) async {
    return outboxStore.enqueue(
      OutboxEntry(
        id: '${operation.name}:${media.id}:${DateTime.now().microsecondsSinceEpoch}',
        operation: operation,
        organizationId: await activeOrganizationStore?.read(),
        payload: <String, dynamic>{
          'id': media.id,
          'post_id': media.postId,
          'url': media.url,
          'mime_type': media.mimeType,
          'size_in_bytes': media.sizeInBytes,
          'is_compressed': media.isCompressed,
          // On web there is no real file path to re-read from when this is
          // replayed later — the bytes have to travel with the queued entry
          // itself, or a retried upload would have no content to send.
          if (media.bytes != null) 'bytes_base64': base64Encode(media.bytes!),
        },
        resumeToken: operation == OutboxOperation.uploadMedia ? media.id : null,
      ),
    );
  }

  Future<void> _enqueueDeleteOperation(String mediaId) async {
    return outboxStore.enqueue(
      OutboxEntry(
        id: 'deleteMedia:$mediaId:${DateTime.now().microsecondsSinceEpoch}',
        operation: OutboxOperation.deleteMedia,
        organizationId: await activeOrganizationStore?.read(),
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
