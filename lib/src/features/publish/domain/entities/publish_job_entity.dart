import '../../../../core/base/base_entity.dart';

enum PublishStatus { queued, publishing, published, failed, retrying }

class PublishJobEntity extends BaseEntity {
  const PublishJobEntity({
    required this.id,
    required this.postId,
    this.status = PublishStatus.queued,
    this.retryCount = 0,
    this.progress = 0,
    this.errorMessage,
  });

  @override
  final String id;
  final String postId;
  final PublishStatus status;
  final int retryCount;
  final int progress;
  final String? errorMessage;
}
