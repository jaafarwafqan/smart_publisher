import '../../../../core/base/base_entity.dart';

class DraftEntity extends BaseEntity {
  const DraftEntity({
    required this.id,
    required this.postId,
    required this.content,
    this.updatedAt,
  });

  @override
  final String id;
  final String postId;
  final String content;
  final DateTime? updatedAt;
}
