import 'publish_job.dart';

class PublishBatch {
  const PublishBatch({required this.jobs});

  final List<PublishJob> jobs;
}
