import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/core/result/app_result.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';

void main() {
  group('PostRepositoryImpl', () {
    test('create/get/list/delete works in local mode', () async {
      final repo = PostRepositoryImpl();
      const post = PostEntity(id: 'p1', title: 'title', body: 'body');

      final created = await repo.createPost(post);
      expect(created.isSuccess, isTrue);

      final loaded = await repo.getPost('p1');
      expect(loaded.isSuccess, isTrue);
      expect(loaded.data?.title, 'title');

      final list = await repo.getPosts();
      expect(list.data?.length, 1);

      final deleted = await repo.deletePost('p1');
      expect(deleted.isSuccess, isTrue);

      final afterDelete = await repo.getPost('p1');
      expect(afterDelete.isFailure, isTrue);
      expect(afterDelete.failure, isA<ValidationFailure>());
    });
  });
}
