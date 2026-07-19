import '../../../../core/base/base_entity.dart';

class MediaEntity extends BaseEntity {
  const MediaEntity({
    required this.id,
    required this.postId,
    required this.url,
    this.mimeType = 'application/octet-stream',
    this.sizeInBytes = 0,
    this.isCompressed = false,
  });

  @override
  final String id;
  final String postId;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final bool isCompressed;
}
