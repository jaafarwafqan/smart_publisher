import '../core/media_metadata.dart';

class MetadataExtractor {
  const MetadataExtractor();

  MediaMetadata extract({
    required String url,
    required String mimeType,
    required int sizeInBytes,
  }) {
    final normalizedMime = mimeType.trim().toLowerCase();
    final normalizedUrl = url.trim();

    String extension = '';
    final uri = Uri.tryParse(normalizedUrl);
    final path = uri?.path ?? normalizedUrl;
    if (path.contains('.')) {
      extension = path.split('.').last.toLowerCase();
    }

    final isImage = normalizedMime.startsWith('image/');
    final isVideo = normalizedMime.startsWith('video/');

    return MediaMetadata(
      mimeType: normalizedMime,
      sizeInBytes: sizeInBytes,
      fileExtension: extension,
      isImage: isImage,
      isVideo: isVideo,
      width: isImage ? 1080 : null,
      height: isImage ? 1080 : null,
      durationMs: isVideo ? 30000 : null,
    );
  }
}
