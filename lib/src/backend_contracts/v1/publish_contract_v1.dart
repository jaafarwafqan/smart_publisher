class PublishJobRequestDtoV1 {
  const PublishJobRequestDtoV1({
    required this.postId,
    this.platformIds = const <String>[],
    this.scheduleAt,
  });

  final String postId;
  final List<String> platformIds;
  final DateTime? scheduleAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'post_id': postId,
      'platform_ids': platformIds,
      'schedule_at': scheduleAt?.toIso8601String(),
    };
  }
}

class PublishJobUpdateRequestDtoV1 {
  const PublishJobUpdateRequestDtoV1({required this.status, this.progress});

  final String status;
  final int? progress;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'status': status, 'progress': progress};
  }
}

class PublishJobResponseDtoV1 {
  const PublishJobResponseDtoV1({
    required this.id,
    required this.postId,
    required this.status,
    required this.retryCount,
    required this.progress,
  });

  final String id;
  final String postId;
  final String status;
  final int retryCount;
  final int progress;

  factory PublishJobResponseDtoV1.fromJson(Map<String, dynamic> json) {
    final retryCountRaw = json['retry_count'];
    final progressRaw = json['progress'];
    return PublishJobResponseDtoV1(
      id: (json['id'] ?? '') as String,
      postId: (json['post_id'] ?? '') as String,
      status: (json['status'] ?? 'queued') as String,
      retryCount: retryCountRaw is num
          ? retryCountRaw.toInt()
          : int.tryParse('$retryCountRaw') ?? 0,
      progress: progressRaw is num
          ? progressRaw.toInt()
          : int.tryParse('$progressRaw') ?? 0,
    );
  }
}
