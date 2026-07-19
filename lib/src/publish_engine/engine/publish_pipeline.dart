import 'publish_context.dart';
import 'publish_step.dart';

class PublishPipeline {
  const PublishPipeline(this.steps);

  final List<PublishStep> steps;

  Future<void> run(PublishContext context) async {
    for (final step in steps) {
      await step.execute(context);
    }
  }
}
