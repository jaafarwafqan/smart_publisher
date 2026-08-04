import 'dart:convert';

import '../../features/posts/domain/entities/post_entity.dart';
import '../../features/posts/domain/repositories/post_repository.dart';
import '../../features/media/domain/repositories/media_repository.dart';
import '../../features/posts/domain/entities/media_entity.dart';
import '../queue/outbox_entry.dart';
import 'sync_worker.dart';

/// Builds the handler map [SyncWorker.runOnce] needs to actually replay
/// queued offline operations against the network. Without this, entries
/// enqueued by [PostRepository]/[MediaRepository] on a [NetworkFailure] would
/// sit in the outbox forever even once SyncWorker is triggered.
Map<OutboxOperation, OutboxSyncHandler> buildOutboxSyncHandlers({
  required PostRepository postRepository,
  required MediaRepository mediaRepository,
}) {
  return <OutboxOperation, OutboxSyncHandler>{
    OutboxOperation.createPost: (entry) async {
      final result = await postRepository.createPost(
        _postFromPayload(entry.payload),
      );
      if (result.isFailure) {
        throw StateError(result.message ?? 'Failed to sync created post');
      }
    },
    OutboxOperation.updatePost: (entry) async {
      final result = await postRepository.updatePost(
        _postFromPayload(entry.payload),
      );
      if (result.isFailure) {
        throw StateError(result.message ?? 'Failed to sync updated post');
      }
    },
    OutboxOperation.deletePost: (entry) async {
      final result = await postRepository.deletePost(
        entry.payload['id'] as String,
      );
      if (result.isFailure) {
        throw StateError(result.message ?? 'Failed to sync deleted post');
      }
    },
    OutboxOperation.uploadMedia: (entry) async {
      final result = await mediaRepository.uploadMedia(
        _mediaFromPayload(entry.payload),
      );
      if (result.isFailure) {
        throw StateError(result.message ?? 'Failed to sync uploaded media');
      }
    },
    OutboxOperation.compressMedia: (entry) async {
      final result = await mediaRepository.compressMedia(
        _mediaFromPayload(entry.payload),
      );
      if (result.isFailure) {
        throw StateError(result.message ?? 'Failed to sync compressed media');
      }
    },
    OutboxOperation.deleteMedia: (entry) async {
      final result = await mediaRepository.deleteMedia(
        entry.payload['id'] as String,
      );
      if (result.isFailure) {
        throw StateError(result.message ?? 'Failed to sync deleted media');
      }
    },
  };
}

PostEntity _postFromPayload(Map<String, dynamic> payload) {
  final rawPlatformContent =
      payload['platform_content'] as Map<String, dynamic>? ??
      const <String, dynamic>{};

  return PostEntity(
    id: payload['id'] as String,
    title: payload['title'] as String? ?? '',
    body: payload['body'] as String? ?? '',
    status: payload['status'] as String? ?? 'draft',
    createdAt: _dateFromPayload(payload['created_at']),
    updatedAt: _dateFromPayload(payload['updated_at']),
    scheduledAt: _dateFromPayload(payload['scheduled_at']),
    attachments: (payload['attachments'] as List<dynamic>? ?? const <dynamic>[])
        .cast<String>(),
    platforms: (payload['platforms'] as List<dynamic>? ?? const <dynamic>[])
        .cast<String>(),
    targetPageIds:
        (payload['target_page_ids'] as List<dynamic>? ?? const <dynamic>[])
            .map((id) => id.toString())
            .toList(),
    platformContent: rawPlatformContent.map(
      (key, value) => MapEntry(key, value.toString()),
    ),
  );
}

MediaEntity _mediaFromPayload(Map<String, dynamic> payload) {
  final encodedBytes = payload['bytes_base64'] as String?;
  return MediaEntity(
    id: payload['id'] as String,
    postId: payload['post_id'] as String? ?? '',
    url: payload['url'] as String? ?? '',
    mimeType: payload['mime_type'] as String? ?? 'application/octet-stream',
    sizeInBytes: payload['size_in_bytes'] as int? ?? 0,
    isCompressed: payload['is_compressed'] as bool? ?? false,
    bytes: encodedBytes != null ? base64Decode(encodedBytes) : null,
  );
}

DateTime? _dateFromPayload(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
