import '../../../dashboard/presentation/utils/platform_label.dart';

/// Four states, matching exactly what a user can actually do in the app
/// today — never a marketing label. Derived from the same predicates
/// `AccountCard`/`dashboard_screen.dart` already use ([isBetaLaunchPlatform]/
/// [isMockBackedPlatform]), not a second hand-maintained list.
enum PlatformReadiness {
  /// Real OAuth/bot connect, real publish, real Page/channel discovery.
  /// Today: Facebook, Telegram, and (2026-08) Instagram — though Instagram's
  /// own [PlatformHelpStatus] still reports `canConnect: false` since it has
  /// no separate OAuth of its own; see `platformHelpStatuses()` below.
  availableBeta,

  /// A real (non-mock) backend provider exists, but the platform isn't
  /// offered in the Connect UI yet — for one of two distinct reasons, both
  /// mapped to this same state since the visible result (no connect/
  /// publish action) is identical:
  ///  - WhatsApp: `publishPost()` genuinely throws "not implemented" —
  ///    Cloud API messages need a fixed recipient number, not a fit for
  ///    this app's "publish to my own audience" model yet.
  ///  - X (`twitter` locally): `XOAuthProvider` is real and fully
  ///    implemented, but not yet in `CLOSED_BETA_PROVIDERS` on the
  ///    backend — its write access needs a paid API tier that hasn't been
  ///    live-verified against a real account yet.
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
        // Checked before the generic isBetaLaunchPlatform branch below:
        // Instagram satisfies that predicate too (it's launched), but has
        // no OAuth/test-connection of its own — an Instagram Business
        // Account is only ever discovered as a child of a connected
        // Facebook Page (see FacebookOAuthProvider::listPages() on the
        // backend, and dashboard_screen.dart's
        // _showInstagramManagedViaFacebookDialog).
        if (platformId == 'instagram') {
          return const PlatformHelpStatus(
            platformId: 'instagram',
            readiness: PlatformReadiness.availableBeta,
            canConnect: false,
            canDiscoverPages: true,
            canTestConnection: false,
            canPublish: true,
          );
        }
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
        if (platformId == 'whatsapp' || platformId == 'twitter') {
          return PlatformHelpStatus(
            platformId: platformId,
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
