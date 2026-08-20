import '../features/posts/domain/entities/media_entity.dart';
import 'core/media_metadata.dart';
import 'processing/metadata_extractor.dart';
import 'processing/thumbnail_generator.dart';
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
    this.thumbnailGenerator = const ThumbnailGenerator(),
  });

  final MetadataExtractor metadataExtractor;
  final MediaValidation validation;
  final ThumbnailGenerator thumbnailGenerator;

  // Was routing both prepareForUpload and compress through a private
  // _compressInternal that estimated a "compressed" sizeInBytes/isCompressed
  // via ImageCompressor/VideoCompressor — pure arithmetic (originalSize *
  // ratio) that never touched a single byte of media.bytes. That fake number
  // fed MediaRepositoryImpl.uploadMedia()'s uploadManager.start(totalBytes:
  // ...), so the upload progress bar tracked a size the upload never
  // actually sent; and on a network failure, MediaRepositoryImpl
  // .compressMedia() shipped a MediaEntity claiming isCompressed: true at a
  // smaller size while the bytes hadn't changed at all. Compression is real
  // work the backend does (intervention/image) via POST /media/{id}/compress
  // — this engine now only validates and derives a thumbnail, always
  // reporting the media's true, unmodified size. MediaRepositoryImpl shows
  // the server's compression result, never a local guess.
  MediaProcessingResult prepareForUpload(MediaEntity media) => _process(media);

  MediaProcessingResult compress(MediaEntity media) => _process(media);

  MediaProcessingResult _process(MediaEntity media) {
    final metadata = metadataExtractor.extract(
      url: media.url,
      mimeType: media.mimeType,
      sizeInBytes: media.sizeInBytes,
    );
    validation.validate(metadata, sourceUrl: media.url);

    final thumbnail = (metadata.isImage || metadata.isVideo)
        ? thumbnailGenerator.generate(media.url)
        : null;

    return MediaProcessingResult(
      media: media,
      metadata: metadata,
      thumbnailUrl: thumbnail,
    );
  }
}
