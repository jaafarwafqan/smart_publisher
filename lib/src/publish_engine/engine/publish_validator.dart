import '../engine/publish_context.dart';
import '../engine/publish_step.dart';

class ValidateStep implements PublishStep {
  @override
  Future<void> execute(PublishContext context) async {
    if (context.post.title.isEmpty || context.post.body.isEmpty) {
      throw StateError('Post title and body are required.');
    }
  }
}
