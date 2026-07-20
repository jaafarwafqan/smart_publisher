class PostModel {
  const PostModel({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    this.createdAt,
    this.updatedAt,
    required this.aiImproved,
    required this.hasMedia,
    this.scheduledAt,
    this.attachments = const <String>[],
    this.platforms = const <String>[],
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
  final List<String> attachments;
  final List<String> platforms;
}
