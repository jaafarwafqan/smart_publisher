enum ReleaseChannel { stable, canary }

class ReleaseConfig {
  ReleaseConfig({required this.channel, required int canaryPercent})
    : canaryPercent = canaryPercent.clamp(0, 100);

  factory ReleaseConfig.fromEnvironment() {
    final rawChannel = const String.fromEnvironment(
      'SP_RELEASE_CHANNEL',
      defaultValue: 'stable',
    ).toLowerCase();
    final rawPercent = const String.fromEnvironment(
      'SP_CANARY_PERCENT',
      defaultValue: '0',
    );

    final channel = rawChannel == 'canary'
        ? ReleaseChannel.canary
        : ReleaseChannel.stable;
    final percent = int.tryParse(rawPercent) ?? 0;

    return ReleaseConfig(channel: channel, canaryPercent: percent);
  }

  final ReleaseChannel channel;
  final int canaryPercent;

  bool get isCanary => channel == ReleaseChannel.canary;

  bool isUserInCanary(String key) {
    if (!isCanary || canaryPercent <= 0) {
      return false;
    }
    final hash = key.runes.fold<int>(
      0,
      (acc, value) => ((acc * 31) + value) & 0x7fffffff,
    );
    final bucket = hash % 100;
    return bucket < canaryPercent;
  }
}
