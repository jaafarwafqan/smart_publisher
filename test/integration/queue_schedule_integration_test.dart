import 'package:flutter_test/flutter_test.dart';
import 'package:smart_publisher/src/features/posts/data/post_repository_impl.dart';
import 'package:smart_publisher/src/features/posts/domain/entities/post_entity.dart';
import 'package:smart_publisher/src/features/posts/domain/usecases/schedule_post.dart';
import 'package:smart_publisher/src/offline/queue/outbox_store.dart';

void main() {
  group('Integration - Queue and Schedule', () {
    test('schedule post updates status and queues change', () async {
      final outbox = OutboxStore();
      final repository = PostRepositoryImpl(outboxStore: outbox);
      final schedule = SchedulePost(repository: repository);

      final post = PostEntity(
        id: 'sched-1',
        title: 'Scheduled',
        body: 'Body',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      );

      await repository.createPost(post);
      final result = await schedule(post);

      expect(result.isSuccess, isTrue);
      expect(result.data?.status, 'scheduled');

      final due = await outbox.dueItems();
      expect(due, isNotEmpty);
    });
  });
}
