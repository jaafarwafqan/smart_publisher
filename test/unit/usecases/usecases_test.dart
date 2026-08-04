import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/base/pagination.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/features/media/domain/repositories/media_repository.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/media_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/repositories/post_repository.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/compress_media.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/create_post.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/publish_post.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/schedule_post.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/upload_media.dart';
import 'package:smart_publisher/src/features/schedule/domain/entities/schedule_entity.dart';
import 'package:smart_publisher/src/features/schedule/domain/repositories/schedule_repository.dart';

void main() {
  group('UseCases', () {
    final post = PostEntity(id: 'p1', title: 't', body: 'b');
    final media = MediaEntity(
      id: 'm1',
      postId: 'p1',
      url: 'https://cdn/a.jpg',
      mimeType: 'image/jpeg',
      sizeInBytes: 1000,
    );

    test('CreatePost delegates to repository.createPost', () async {
      final repo = _FakePostRepository();
      final useCase = CreatePost(repository: repo);

      final result = await useCase(post);

      expect(result.isSuccess, isTrue);
      expect(repo.createCalls, 1);
      expect(result.data?.id, 'p1');
    });

    test('PublishPost sets status to published', () async {
      final repo = _FakePostRepository();
      final useCase = PublishPost(repository: repo);

      final result = await useCase(post);

      expect(result.isSuccess, isTrue);
      expect(repo.lastUpdated?.status, 'published');
    });

    test(
      'SchedulePost delegates to ScheduleRepository.schedulePost, not updatePost',
      () async {
        final repo = _FakeScheduleRepository();
        final useCase = SchedulePost(repository: repo);

        final result = await useCase(
          PostEntity(
            id: post.id,
            title: post.title,
            body: post.body,
            scheduledAt: DateTime.now().add(const Duration(hours: 2)),
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(repo.scheduleCalls, 1);
        expect(repo.lastScheduled?.id, post.id);
      },
    );

    test('SchedulePost fails fast when scheduledAt is missing', () async {
      final repo = _FakeScheduleRepository();
      final useCase = SchedulePost(repository: repo);

      final result = await useCase(post);

      expect(result.isSuccess, isFalse);
      expect(repo.scheduleCalls, 0);
    });

    test('UploadMedia delegates to media repository', () async {
      final repo = _FakeMediaRepository();
      final useCase = UploadMedia(repository: repo);

      final result = await useCase(media);

      expect(result.isSuccess, isTrue);
      expect(repo.uploadCalls, 1);
      expect(result.data?.id, media.id);
    });

    test('CompressMedia delegates to media repository', () async {
      final repo = _FakeMediaRepository();
      final useCase = CompressMedia(repository: repo);

      final result = await useCase(media);

      expect(result.isSuccess, isTrue);
      expect(repo.compressCalls, 1);
    });
  });
}

class _FakePostRepository extends PostRepository {
  int createCalls = 0;
  PostEntity? lastUpdated;

  @override
  Future<AppResult<PostEntity>> createPost(PostEntity post) async {
    createCalls += 1;
    return Success<PostEntity>(post);
  }

  @override
  Future<AppResult<void>> deletePost(String id) async {
    return const Success<void>(null);
  }

  @override
  Future<AppResult<PostEntity>> getPost(String id) async {
    return Success<PostEntity>(PostEntity(id: id, title: 't', body: 'b'));
  }

  @override
  Future<AppResult<List<PostEntity>>> getPosts() async {
    return const Success<List<PostEntity>>(<PostEntity>[]);
  }

  @override
  Future<AppResult<PaginatedResult<PostEntity>>> getPostsPage({
    int page = 1,
  }) async {
    return const Success<PaginatedResult<PostEntity>>(
      PaginatedResult<PostEntity>(
        items: <PostEntity>[],
        page: 1,
        pageSize: 20,
        totalCount: 0,
      ),
    );
  }

  @override
  Future<AppResult<PostEntity>> updatePost(PostEntity post) async {
    lastUpdated = post;
    return Success<PostEntity>(post);
  }

  @override
  Future<AppResult<void>> publishNow(
    String postId, {
    List<String> socialPageIds = const <String>[],
  }) async {
    return const Success<void>(null);
  }
}

class _FakeScheduleRepository extends ScheduleRepository {
  int scheduleCalls = 0;
  PostEntity? lastScheduled;

  @override
  Future<AppResult<PostEntity>> schedulePost(PostEntity post) async {
    scheduleCalls += 1;
    lastScheduled = post;
    return Success<PostEntity>(post.copyWith(status: 'scheduled'));
  }

  @override
  Future<AppResult<void>> cancelSchedule(String postId) async {
    return const Success<void>(null);
  }

  @override
  Future<AppResult<List<ScheduleEntity>>> getCalendarEntries() async {
    return const Success<List<ScheduleEntity>>(<ScheduleEntity>[]);
  }
}

class _FakeMediaRepository extends MediaRepository {
  int uploadCalls = 0;
  int compressCalls = 0;

  @override
  Future<AppResult<MediaEntity>> uploadMedia(MediaEntity media) async {
    uploadCalls += 1;
    return Success<MediaEntity>(media);
  }

  @override
  Future<AppResult<MediaEntity>> compressMedia(MediaEntity media) async {
    compressCalls += 1;
    return Success<MediaEntity>(
      MediaEntity(
        id: media.id,
        postId: media.postId,
        url: media.url,
        mimeType: media.mimeType,
        sizeInBytes: media.sizeInBytes,
        isCompressed: true,
      ),
    );
  }

  @override
  Future<AppResult<void>> deleteMedia(String id) async {
    return const Success<void>(null);
  }

  @override
  Future<AppResult<List<MediaEntity>>> getMediaLibrary({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
  }) async {
    return const Success<List<MediaEntity>>(<MediaEntity>[]);
  }

  @override
  Future<AppResult<PaginatedResult<MediaEntity>>> getMediaLibraryPage({
    String? collection,
    String? type,
    List<String>? tags,
    String? search,
    int page = 1,
  }) async {
    return const Success<PaginatedResult<MediaEntity>>(
      PaginatedResult<MediaEntity>(
        items: <MediaEntity>[],
        page: 1,
        pageSize: 30,
        totalCount: 0,
      ),
    );
  }

  @override
  Future<AppResult<void>> attachMediaToPost({
    required String mediaId,
    required String postId,
  }) async {
    return const Success<void>(null);
  }
}
