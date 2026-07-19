import 'publish_context.dart';

abstract class PublishStep {
  Future<void> execute(PublishContext context);
}
