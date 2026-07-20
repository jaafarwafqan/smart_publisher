import '../features/posts/domain/entities/media_entity.dart';
import 'core/media_metadata.dart';
import 'processing/image_compressor.dart';
import 'processing/metadata_extractor.dart';
import 'processing/thumbnail_generator.dart';
import 'processing/video_compressor.dart';
import 'validation/media_validation.dart';

class MediaProcessingResult {
  const MediaProcessingResult({
    required this.media,
    required this.metadata,
    this.thumbnailUrl,
  });

  final MediaEntity media;
  final MediaMetadata metadata;
  final String? thumbnailUrl;
}

class MediaEngine {
  const MediaEngine({
    this.metadataExtractor = const MetadataExtractor(),
    this.validation = const MediaValidation(),
    this.imageCompressor = const ImageCompressor(),
    this.videoCompressor = const VideoCompressor(),
    this.thumbnailGenerator = const ThumbnailGenerator(),
  });

  final MetadataExtractor metadataExtractor;
  final MediaValidation validation;
  final ImageCompressor imageCompressor;
  final VideoCompressor videoCompressor;
  final ThumbnailGenerator thumbnailGenerator;

  MediaProcessingResult prepareForUpload(MediaEntity media) {
    final metadata = metadataExtractor.extract(
      url: media.url,
      mimeType: media.mimeType,
      sizeInBytes: media.sizeInBytes,
    );
    validation.validate(metadata, sourceUrl: media.url);

    final processedMedia = _compressInternal(media: media, metadata: metadata);
    final thumbnail = (metadata.isImage || metadata.isVideo)
        ? thumbnailGenerator.generate(media.url)
        : null;

    return MediaProcessingResult(
      media: processedMedia,
      metadata: metadataExtractor.extract(
        url: processedMedia.url,
        mimeType: processedMedia.mimeType,
        sizeInBytes: processedMedia.sizeInBytes,
      ),
      thumbnailUrl: thumbnail,
    );
  }

  MediaProcessingResult compress(MediaEntity media) {
    final metadata = metadataExtractor.extract(
      url: media.url,
      mimeType: media.mimeType,
      sizeInBytes: media.sizeInBytes,
    );
    validation.validate(metadata, sourceUrl: media.url);

    final processedMedia = _compressInternal(media: media, metadata: metadata);
    final thumbnail = (metadata.isImage || metadata.isVideo)
        ? thumbnailGenerator.generate(media.url)
        : null;

    return MediaProcessingResult(
      media: processedMedia,
      metadata: metadataExtractor.extract(
        url: processedMedia.url,
        mimeType: processedMedia.mimeType,
        sizeInBytes: processedMedia.sizeInBytes,
      ),
      thumbnailUrl: thumbnail,
    );
  }

  MediaEntity _compressInternal({
    required MediaEntity media,
    required MediaMetadata metadata,
  }) {
    final compressedSize = metadata.isVideo
        ? videoCompressor.compressSize(media.sizeInBytes)
        : metadata.isImage
        ? imageCompressor.compressSize(media.sizeInBytes)
        : media.sizeInBytes;

    final hasCompression = metadata.isVideo || metadata.isImage;
    return MediaEntity(
      id: media.id,
      postId: media.postId,
      url: media.url,
      mimeType: media.mimeType,
      sizeInBytes: compressedSize,
      isCompressed: hasCompression || media.isCompressed,
    );
  }
}
