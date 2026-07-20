class MediaModel {
  const MediaModel({
    required this.id,
    required this.postId,
    required this.url,
    required this.mimeType,
    required this.sizeInBytes,
    required this.isCompressed,
  });

  final String id;
  final String postId;
  final String url;
  final String mimeType;
  final int sizeInBytes;
  final bool isCompressed;
}
