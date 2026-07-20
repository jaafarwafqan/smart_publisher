import '../../features/posts/domain/entities/post_entity.dart';
import '../../domain/publish_target.dart';

class PublishJob {
  PublishJob({
    required this.id,
    required this.postId,
    required this.post,
    required this.targets,
    this.status = PublishJobStatus.pending,
    this.retryCount = 0,
    this.lastErrorCode,
    this.lastErrorMessage,
    this.nextRetryAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String postId;
  final PostEntity post;
  final List<PublishTarget> targets;
  final PublishJobStatus status;
  final int retryCount;
  final String? lastErrorCode;
  final String? lastErrorMessage;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  PublishJob copyWith({
    PublishJobStatus? status,
    int? retryCount,
    String? lastErrorCode,
    String? lastErrorMessage,
    DateTime? nextRetryAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearRetryAt = false,
    bool clearError = false,
  }) {
    return PublishJob(
      id: id,
      postId: postId,
      post: post,
      targets: targets,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastErrorCode: clearError ? null : (lastErrorCode ?? this.lastErrorCode),
      lastErrorMessage: clearError
          ? null
          : (lastErrorMessage ?? this.lastErrorMessage),
      nextRetryAt: clearRetryAt ? null : (nextRetryAt ?? this.nextRetryAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

enum PublishJobStatus { pending, processing, succeeded, failed }
