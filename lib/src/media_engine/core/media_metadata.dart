class MediaMetadata {
  const MediaMetadata({
    required this.mimeType,
    required this.sizeInBytes,
    required this.fileExtension,
    required this.isImage,
    required this.isVideo,
    this.width,
    this.height,
    this.durationMs,
  });

  final String mimeType;
  final int sizeInBytes;
  final String fileExtension;
  final bool isImage;
  final bool isVideo;
  final int? width;
  final int? height;
  final int? durationMs;
}
