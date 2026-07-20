class PostAnalyticsResponseDtoV1 {
  const PostAnalyticsResponseDtoV1({
    required this.postId,
    required this.impressions,
    required this.clicks,
    required this.shares,
    required this.reactions,
    required this.status,
  });

  final String postId;
  final int impressions;
  final int clicks;
  final int shares;
  final int reactions;
  final String status;

  factory PostAnalyticsResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return PostAnalyticsResponseDtoV1(
      postId: (json['post_id'] ?? '') as String,
      impressions: (json['impressions'] ?? 0) as int,
      clicks: (json['clicks'] ?? 0) as int,
      shares: (json['shares'] ?? 0) as int,
      reactions: (json['reactions'] ?? 0) as int,
      status: (json['status'] ?? 'draft') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'post_id': postId,
      'impressions': impressions,
      'clicks': clicks,
      'shares': shares,
      'reactions': reactions,
      'status': status,
    };
  }
}
