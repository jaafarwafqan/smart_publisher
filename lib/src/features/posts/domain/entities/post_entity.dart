import '../../../../core/base/base_entity.dart';

class PostEntity extends BaseEntity {
  const PostEntity({
    required this.id,
    required this.title,
    required this.body,
    this.status = 'draft',
    this.createdAt,
    this.updatedAt,
    this.aiImproved = false,
    this.hasMedia = false,
    this.scheduledAt,
    this.attachments = const <String>[],
    this.platforms = const <String>[],
  });

  @override
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

  PostEntity copyWith({
    String? id,
    String? title,
    String? body,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? aiImproved,
    bool? hasMedia,
    DateTime? scheduledAt,
    List<String>? attachments,
    List<String>? platforms,
  }) {
    return PostEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      aiImproved: aiImproved ?? this.aiImproved,
      hasMedia: hasMedia ?? this.hasMedia,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      attachments: attachments ?? this.attachments,
      platforms: platforms ?? this.platforms,
    );
  }
}
