import '../../features/posts/domain/entities/media_entity.dart';

class MediaService {
  const MediaService();

  Future<MediaEntity> validateAndPrepare(MediaEntity media) async {
    return media;
  }
}
