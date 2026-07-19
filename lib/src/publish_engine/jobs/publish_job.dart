import '../../platforms/core/platform_type.dart';

class PublishJob {
  const PublishJob({
    required this.id,
    required this.postId,
    required this.platforms,
    this.status = 'pending',
    this.retryCount = 0,
  });

  final String id;
  final String postId;
  final List<PlatformType> platforms;
  final String status;
  final int retryCount;
}
