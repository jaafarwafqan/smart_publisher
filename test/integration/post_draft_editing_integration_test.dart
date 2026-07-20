import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/create_post.dart';

void main() {
  group('Integration - Post Draft Editing', () {
    test(
      'existing draft can be updated with new content/media/platforms',
      () async {
        final repository = PostRepositoryImpl();
        final createPost = CreatePost(repository: repository);

        final created = await createPost(
          const PostEntity(
            id: 'draft-edit-1',
            title: 'Initial title',
            body: 'Initial body',
            status: 'draft',
            attachments: <String>['https://cdn.initial/media-1.png'],
            platforms: <String>['facebook'],
            hasMedia: true,
          ),
        );

        expect(created.isSuccess, isTrue);
        expect(created.data, isNotNull);

        final updated = await repository.updatePost(
          created.data!.copyWith(
            title: 'Updated title',
            body: 'Updated body for draft editor',
            attachments: const <String>[
              'https://cdn.updated/media-1.png',
              'https://cdn.updated/media-2.mp4',
            ],
            platforms: const <String>['facebook', 'linkedin'],
            updatedAt: DateTime.now(),
            hasMedia: true,
          ),
        );

        expect(updated.isSuccess, isTrue);
        expect(updated.data, isNotNull);
        expect(updated.data!.title, 'Updated title');
        expect(updated.data!.body, 'Updated body for draft editor');
        expect(updated.data!.attachments.length, 2);
        expect(
          updated.data!.platforms,
          containsAll(<String>['facebook', 'linkedin']),
        );
      },
    );
  });
}
