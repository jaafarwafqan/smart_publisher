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
}
