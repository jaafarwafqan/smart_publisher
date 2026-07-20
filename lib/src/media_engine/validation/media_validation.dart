import '../core/media_engine_exception.dart';
import '../core/media_metadata.dart';

class MediaValidation {
  const MediaValidation({
    this.maxImageBytes = 20 * 1024 * 1024,
    this.maxVideoBytes = 500 * 1024 * 1024,
  });

  final int maxImageBytes;
  final int maxVideoBytes;

  void validate(MediaMetadata metadata, {required String sourceUrl}) {
    if (sourceUrl.trim().isEmpty) {
      throw const MediaEngineException(
        'Media URL is required.',
        code: 'MED_VAL_URL_EMPTY',
      );
    }

    if (!metadata.mimeType.contains('/')) {
      throw const MediaEngineException(
        'Media MIME type must be in format type/subtype.',
        code: 'MED_VAL_MIME_INVALID',
      );
    }

    if (metadata.sizeInBytes <= 0) {
      throw const MediaEngineException(
        'Media size must be greater than zero.',
        code: 'MED_VAL_SIZE_INVALID',
      );
    }

    if (metadata.isImage && metadata.sizeInBytes > maxImageBytes) {
      throw MediaEngineException(
        'Image exceeds max allowed size (${maxImageBytes ~/ (1024 * 1024)} MB).',
        code: 'MED_VAL_IMAGE_TOO_LARGE',
      );
    }

    if (metadata.isVideo && metadata.sizeInBytes > maxVideoBytes) {
      throw MediaEngineException(
        'Video exceeds max allowed size (${maxVideoBytes ~/ (1024 * 1024)} MB).',
        code: 'MED_VAL_VIDEO_TOO_LARGE',
      );
    }
  }
}
