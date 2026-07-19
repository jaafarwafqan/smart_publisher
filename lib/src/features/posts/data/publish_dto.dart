class PublishDto {
  const PublishDto({
    required this.postId,
    required this.platformId,
    this.status = 'queued',
    this.retryCount = 0,
    this.progress = 0,
  });

  final String postId;
  final String platformId;
  final String status;
  final int retryCount;
  final int progress;

  Map<String, dynamic> toJson() => {
    'postId': postId,
    'platformId': platformId,
    'status': status,
    'retryCount': retryCount,
    'progress': progress,
  };
}
