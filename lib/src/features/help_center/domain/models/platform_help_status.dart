import '../../../dashboard/presentation/utils/platform_label.dart';

/// Four states, matching exactly what a user can actually do in the app
/// today — never a marketing label. Derived from the same predicates
/// `AccountCard`/`dashboard_screen.dart` already use ([isBetaLaunchPlatform]/
/// [isMockBackedPlatform]), not a second hand-maintained list.
enum PlatformReadiness {
  /// Real OAuth/bot connect, real publish, real Page/channel discovery.
  /// Today: Facebook, Telegram only.
  availableBeta,

  /// A real (non-mock) backend provider exists but publishing is not
  /// implemented — the Connect UI still shows "Coming soon" because
  /// [isBetaLaunchPlatform] gates on more than "does a real provider
  /// exist." Today: WhatsApp only (real OAuth + Page discovery once a
  /// Meta Business ID is set, `publishPost()` throws "not implemented").
  partial,

  /// Backed by `GenericOAuthProvider` on the backend — a connect/publish
  /// call would succeed with zero real HTTP request. Never offered as
  /// connectable in the UI.
  comingSoonMock,
}

class PlatformHelpStatus {
  const PlatformHelpStatus({
    required this.platformId,
    required this.readiness,
    required this.canConnect,
    required this.canDiscoverPages,
    required this.canTestConnection,
    required this.canPublish,
  });

  final String platformId;
  final PlatformReadiness readiness;
  final bool canConnect;
  final bool canDiscoverPages;
  final bool canTestConnection;
  final bool canPublish;

  String get label => platformLabel(platformId);
}

/// The fixed six placeholder platforms the dashboard actually renders (see
/// `AccountRepositoryImpl._defaultPermissionsByPlatform`) — the guide must
/// not describe a platform the account list itself never shows.
const List<String> helpCenterPlatformIds = <String>[
  'facebook',
  'instagram',
  'telegram',
  'whatsapp',
  'linkedin',
  'twitter',
];

List<PlatformHelpStatus> platformHelpStatuses() {
  return helpCenterPlatformIds
      .map((platformId) {
        if (isBetaLaunchPlatform(platformId)) {
          return PlatformHelpStatus(
            platformId: platformId,
            readiness: PlatformReadiness.availableBeta,
            canConnect: true,
            canDiscoverPages: true,
            canTestConnection: true,
            canPublish: true,
          );
        }
        if (platformId == 'whatsapp') {
          return const PlatformHelpStatus(
            platformId: 'whatsapp',
            readiness: PlatformReadiness.partial,
            canConnect: false,
            canDiscoverPages: false,
            canTestConnection: false,
            canPublish: false,
          );
        }
        return PlatformHelpStatus(
          platformId: platformId,
          readiness: PlatformReadiness.comingSoonMock,
          canConnect: false,
          canDiscoverPages: false,
          canTestConnection: false,
          canPublish: false,
        );
      })
      .toList(growable: false);
}
