class MediaDto {
  const MediaDto({
    required this.id,
    required this.postId,
    required this.url,
    this.mimeType = 'application/octet-stream',
    this.sizeInBytes = 0,
    this.isCompressed = false,
  });

  final String id;
  final String postId;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final bool isCompressed;

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'url': url,
    'mimeType': mimeType,
    'sizeInBytes': sizeInBytes,
    'isCompressed': isCompressed,
  };
}
