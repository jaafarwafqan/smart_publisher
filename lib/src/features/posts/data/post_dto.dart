class PostDto {
  const PostDto({
    required this.id,
    required this.title,
    required this.body,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.aiImproved = false,
    this.hasMedia = false,
    this.scheduledAt,
  });

  final String id;
  final String title;
  final String body;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool aiImproved;
  final bool hasMedia;
  final DateTime? scheduledAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'status': status,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'aiImproved': aiImproved,
    'hasMedia': hasMedia,
    'scheduledAt': scheduledAt?.toIso8601String(),
  };
}
