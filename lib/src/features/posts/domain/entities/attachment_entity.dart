import '../../../../core/base/base_entity.dart';

class AttachmentEntity extends BaseEntity {
  const AttachmentEntity({
    required this.id,
    required this.postId,
    required this.name,
    required this.path,
    this.type = 'file',
  });

  @override
  final String id;
  final String postId;
  final String name;
  final String path;
  final String type;
}
