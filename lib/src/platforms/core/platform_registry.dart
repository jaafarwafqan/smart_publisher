import 'social_platform.dart';
import '../../domain/publish_target.dart';

class PlatformRegistry {
  PlatformRegistry({Iterable<SocialPlatform> platforms = const []})
    : _publishers = <String, SocialPlatform>{} {
    registerAll(platforms);
  }

  final Map<String, SocialPlatform> _publishers;

  void register(SocialPlatform publisher) {
    _publishers[publisher.platformId] = publisher;
  }

  void registerAll(Iterable<SocialPlatform> publishers) {
    for (final publisher in publishers) {
      register(publisher);
    }
  }

  SocialPlatform get(String platformId) {
    final publisher = _publishers[platformId];
    if (publisher == null) {
      throw StateError('Publisher not registered for platform: $platformId');
    }
    return publisher;
  }

  List<ResolvedPublisher> resolve(PublishTarget target) {
    final exactMatches = _publishers.values
        .where(
          (publisher) =>
              publisher.supportedTargetKeys.contains(target.destinationKey),
        )
        .map(
          (publisher) => ResolvedPublisher(
            platformId: publisher.platformId,
            publisher: publisher,
          ),
        )
        .toList(growable: false);

    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }

    return _publishers.values
        .where((publisher) => publisher.supportsTarget(target))
        .map(
          (publisher) => ResolvedPublisher(
            platformId: publisher.platformId,
            publisher: publisher,
          ),
        )
        .toList(growable: false);
  }
}

class ResolvedPublisher {
  const ResolvedPublisher({required this.platformId, required this.publisher});

  final String platformId;
  final SocialPlatform publisher;
}
