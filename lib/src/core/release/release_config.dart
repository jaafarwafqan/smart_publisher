/// The only release channel this client is allowed to identify itself as.
/// Progressive rollout plumbing was never backed by a deployment controller,
/// so it is deliberately not represented as an executable client feature.
enum ReleaseChannel { closedBeta }

class ReleaseConfig {
  const ReleaseConfig({this.channel = ReleaseChannel.closedBeta});

  factory ReleaseConfig.fromEnvironment() {
    return const ReleaseConfig();
  }

  final ReleaseChannel channel;

  String get wireValue => 'closed-beta';
}
