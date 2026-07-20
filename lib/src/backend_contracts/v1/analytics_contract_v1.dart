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

  static String _asString(Object? value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }
    return fallback;
  }

  factory PostAnalyticsResponseDtoV1.fromJson(Map<String, dynamic> json) {
    return PostAnalyticsResponseDtoV1(
      postId: _asString(json['post_id']),
      impressions: _asInt(json['impressions']),
      clicks: _asInt(json['clicks']),
      shares: _asInt(json['shares']),
      reactions: _asInt(json['reactions']),
      status: _asString(json['status'], fallback: 'draft'),
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
