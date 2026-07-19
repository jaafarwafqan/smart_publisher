import '../../features/posts/domain/entities/media_entity.dart';
import '../validators/media_validator.dart';

class MediaPolicy {
  const MediaPolicy({this.validator = const MediaValidator()});

  final MediaValidator validator;

  String? validateMedia(MediaEntity? media) {
    if (media == null) {
      return 'Media is required for this operation.';
    }

    final urlError = validator.validateUrl(media.url);
    if (urlError != null) {
      return urlError;
    }

    return validator.validateMimeType(media.mimeType);
  }
}
