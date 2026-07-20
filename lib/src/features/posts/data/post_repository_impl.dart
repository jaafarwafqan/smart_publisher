import '../../../backend_contracts/v1/api_envelope_v1.dart';
import '../../../backend_contracts/v1/backend_contract_mapper_v1.dart';
import '../../../backend_contracts/v1/posts_contract_v1.dart';
import '../../../offline/cache/draft_storage.dart';
import '../../../offline/queue/outbox_entry.dart';
import '../../../offline/queue/outbox_store.dart';
import '../../../core/result/app_result.dart';
import '../../../core/network/network_client.dart';
import '../../../core/network/laravel_api.dart';
import '../../../core/events/event_dispatcher.dart';
import '../domain/entities/post_entity.dart';
import '../domain/repositories/post_repository.dart';
import '../events/post_created_event.dart';
import '../events/post_deleted_event.dart';
import '../events/post_scheduled_event.dart';
import '../../schedule/events/schedule_created_event.dart';

class PostRepositoryImpl extends PostRepository {
  PostRepositoryImpl({
    this.networkClient,
    this.eventDispatcher,
    DraftStorage? draftStorage,
    OutboxStore? outboxStore,
  }) : draftStorage = draftStorage ?? DraftStorage(),
       outboxStore = outboxStore ?? OutboxStore();

  final NetworkClient? networkClient;
  final EventDispatcher? eventDispatcher;
  final DraftStorage draftStorage;
  final OutboxStore outboxStore;

  final Map<String, PostEntity> _inMemoryStore = <String, PostEntity>{};

  @override
  Future<AppResult<PostEntity>> createPost(PostEntity post) async {
    if (networkClient != null) {
      return _createViaNetwork(post);
    }

    return executeTransaction(
      () async {
        _inMemoryStore[post.id] = post;
        await draftStorage.saveDraft(post);
        await _enqueuePostOperation(OutboxOperation.createPost, post);
        await eventDispatcher?.dispatch(PostCreatedEvent(postId: post.id));
        return post;
      },
      operation: 'posts.create.local',
      fallbackMessage: 'Failed to create post locally',
    );
  }

  @override
  Future<AppResult<PostEntity>> updatePost(PostEntity post) async {
    if (networkClient != null) {
      return _updateViaNetwork(post);
    }

    return executeTransaction(
      () async {
        _inMemoryStore[post.id] = post;
        await draftStorage.saveDraft(post);
        await _enqueuePostOperation(OutboxOperation.updatePost, post);
        if (post.status == 'scheduled') {
          await eventDispatcher?.dispatch(
            PostScheduledEvent(postId: post.id, scheduledAt: post.scheduledAt),
          );
          await eventDispatcher?.dispatch(
            ScheduleCreatedEvent(
              postId: post.id,
              scheduledAt: post.scheduledAt,
            ),
          );
        }
        return post;
      },
      operation: 'posts.update.local',
      fallbackMessage: 'Failed to update post locally',
    );
  }

  @override
  Future<AppResult<PostEntity>> getPost(String id) async {
    if (networkClient != null) {
      return _getViaNetwork(id);
    }

    return execute(
      () async {
        final post = _inMemoryStore[id];
        if (post == null) {
          throw StateError('Post not found');
        }
        await afterCacheRead(id, post);
        return post;
      },
      operation: 'posts.get.local',
      fallbackMessage: 'Post not found',
    );
  }

  @override
  Future<AppResult<List<PostEntity>>> getPosts() async {
    if (networkClient != null) {
      return _listViaNetwork();
    }

    return executeList(
      () async => _inMemoryStore.values.toList(),
      operation: 'posts.list.local',
      fallbackMessage: 'Failed to list posts locally',
    );
  }

  @override
  Future<AppResult<void>> deletePost(String id) async {
    if (networkClient != null) {
      return _deleteViaNetwork(id);
    }

    return executeTransaction<void>(
      () async {
        _inMemoryStore.remove(id);
        await draftStorage.deleteDraft(id);
        await _enqueueDeleteOperation(id);
        await eventDispatcher?.dispatch(PostDeletedEvent(postId: id));
      },
      operation: 'posts.delete.local',
      fallbackMessage: 'Failed to delete post locally',
    );
  }

  Future<AppResult<PostEntity>> _createViaNetwork(PostEntity post) async {
    try {
      final dto = BackendContractMapperV1.toPostRequest(post);
      final response = await networkClient!.post(
        LaravelEndpoints.posts,
        data: dto.toJson(),
      );
      final createdPost = _parsePostResponse(response.data);
      return Success<PostEntity>(createdPost, message: 'Post created remotely');
    } catch (error, stackTrace) {
      final failure = mapFailure(
        error,
        stackTrace,
        fallbackMessage: 'Failed to create post',
      );
      if (failure is NetworkFailure) {
        _inMemoryStore[post.id] = post;
        await draftStorage.saveDraft(post);
        await _enqueuePostOperation(OutboxOperation.createPost, post);
        return Success<PostEntity>(post, message: 'Post queued for sync');
      }
      return Failure<PostEntity>.fromFailure(failure);
    }
  }

  Future<AppResult<PostEntity>> _updateViaNetwork(PostEntity post) async {
    try {
      final dto = BackendContractMapperV1.toPostUpdateRequest(post);
      final response = await networkClient!.patch(
        LaravelEndpoints.postById(post.id),
        data: dto.toJson(),
      );
      final updatedPost = _parsePostResponse(response.data);
      if (updatedPost.status == 'scheduled') {
        await eventDispatcher?.dispatch(
          ScheduleCreatedEvent(
            postId: updatedPost.id,
            scheduledAt: updatedPost.scheduledAt,
          ),
        );
      }
      return Success<PostEntity>(updatedPost, message: 'Post updated remotely');
    } catch (error, stackTrace) {
      final failure = mapFailure(
        error,
        stackTrace,
        fallbackMessage: 'Failed to update post',
      );
      if (failure is NetworkFailure) {
        _inMemoryStore[post.id] = post;
        await draftStorage.saveDraft(post);
        await _enqueuePostOperation(OutboxOperation.updatePost, post);
        return Success<PostEntity>(
          post,
          message: 'Post update queued for sync',
        );
      }
      return Failure<PostEntity>.fromFailure(failure);
    }
  }

  Future<AppResult<PostEntity>> _getViaNetwork(String id) async {
    try {
      final response = await networkClient!.get(LaravelEndpoints.postById(id));
      final post = _parsePostResponse(response.data);
      return Success<PostEntity>(post, message: 'Post retrieved remotely');
    } catch (error, stackTrace) {
      return Failure<PostEntity>.fromFailure(
        mapFailure(error, stackTrace, fallbackMessage: 'Failed to get post'),
      );
    }
  }

  Future<AppResult<List<PostEntity>>> _listViaNetwork() async {
    try {
      final response = await networkClient!.get(LaravelEndpoints.posts);
      final payload = _unwrapPayload(response.data);
      final rawItems = payload is List<dynamic>
          ? payload
          : (payload is Map<String, dynamic> &&
                payload['items'] is List<dynamic>)
          ? payload['items'] as List<dynamic>
          : <dynamic>[];

      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(_fromContractResponse)
          .toList();
      return Success<List<PostEntity>>(
        items,
        message: 'Posts retrieved remotely',
      );
    } catch (error, stackTrace) {
      return Failure<List<PostEntity>>.fromFailure(
        mapFailure(error, stackTrace, fallbackMessage: 'Failed to list posts'),
      );
    }
  }

  Future<AppResult<void>> _deleteViaNetwork(String id) async {
    try {
      await networkClient!.delete(LaravelEndpoints.postById(id));
      return const Success<void>(null, message: 'Post deleted remotely');
    } catch (error, stackTrace) {
      final failure = mapFailure(
        error,
        stackTrace,
        fallbackMessage: 'Failed to delete post',
      );
      if (failure is NetworkFailure) {
        await _enqueueDeleteOperation(id);
        return const Success<void>(
          null,
          message: 'Post delete queued for sync',
        );
      }
      return Failure<void>.fromFailure(failure);
    }
  }

  Future<void> _enqueuePostOperation(
    OutboxOperation operation,
    PostEntity post,
  ) {
    return outboxStore.enqueue(
      OutboxEntry(
        id: '${operation.name}:${post.id}:${DateTime.now().microsecondsSinceEpoch}',
        operation: operation,
        payload: <String, dynamic>{
          'id': post.id,
          'title': post.title,
          'body': post.body,
          'status': post.status,
          'attachments': post.attachments,
          'platforms': post.platforms,
          'created_at': post.createdAt?.toIso8601String(),
          'updated_at': post.updatedAt?.toIso8601String(),
          'scheduled_at': post.scheduledAt?.toIso8601String(),
        },
      ),
    );
  }

  Future<void> _enqueueDeleteOperation(String postId) {
    return outboxStore.enqueue(
      OutboxEntry(
        id: 'deletePost:$postId:${DateTime.now().microsecondsSinceEpoch}',
        operation: OutboxOperation.deletePost,
        payload: <String, dynamic>{'id': postId},
      ),
    );
  }

  PostEntity _parsePostResponse(dynamic responseData) {
    final payload = _unwrapPayload(responseData);
    if (payload is! Map<String, dynamic>) {
      throw StateError('Invalid post response payload');
    }
    return _fromContractResponse(payload);
  }

  PostEntity _fromContractResponse(Map<String, dynamic> data) {
    final dto = PostResponseDtoV1.fromJson(data);
    return BackendContractMapperV1.toPostEntity(dto);
  }

  dynamic _unwrapPayload(dynamic raw) {
    if (raw is Map<String, dynamic> && raw.containsKey('success')) {
      return ApiEnvelopeV1.fromJson(raw).data;
    }
    return raw;
  }
}
