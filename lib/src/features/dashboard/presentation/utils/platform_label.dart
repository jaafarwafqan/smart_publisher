/// Shared display-name lookup for platform identifiers, used by both
/// [AccountCard] and [RecentActivityList] so there is one source of truth
/// instead of duplicating this switch statement per widget.
String platformLabel(String platform) {
  switch (platform) {
    case 'facebook':
      return 'Facebook';
    case 'instagram':
      return 'Instagram';
    case 'telegram':
      return 'Telegram';
    case 'whatsapp':
      return 'WhatsApp';
    case 'linkedin':
      return 'LinkedIn';
    case 'twitter':
    case 'x':
      return 'X';
    default:
      return platform;
  }
}

/// CTO audit P0-5: `linkedin`/`twitter` (X) are wired to the backend's
/// `GenericOAuthProvider`, which fakes a successful connect/publish with
/// zero real HTTP calls — connecting them here previously looked identical
/// to a real Facebook/Telegram connection. Until each has a real provider
/// implementation, the Connect UI must not offer them as if they worked.
///
/// `instagram` graduated off this list in 2026-08 — `InstagramProvider`
/// makes real Content Publishing API calls now (see
/// `isBetaLaunchPlatform` below for why it's still not its own separate
/// Connect entry point, though). `x`/`twitter` is real code too
/// (`XOAuthProvider`) but deliberately stays here: it's real, not mock, but
/// not yet production-approved — see `isBetaLaunchPlatform`'s docblock for
/// that distinction, which this predicate does not make (it only answers
/// "would connecting this actually talk to the real platform").
///
/// This mirrors `SocialOAuthManager::isMockProvider()` on the backend by
/// hand; the 30-day backlog item is to replace this with a live capability
/// check against `GET /system-settings/oauth-providers`'s
/// `is_mock_integration` field instead of duplicating the list client-side.
bool isMockBackedPlatform(String platform) {
  switch (platform) {
    case 'linkedin':
    case 'twitter':
    case 'x':
      return true;
    default:
      return false;
  }
}

/// Facebook, Telegram, and (2026-08, after a live-verified real publish —
/// see `InstagramProvider` on the backend) Instagram are the platforms the
/// CTO audit approved for the closed beta launch; everything else stays
/// disabled in the primary Connect UI even if a real provider partially
/// exists (e.g. WhatsApp's discovery works but `publishPost` isn't
/// implemented yet; X's publishing is real but not yet live-verified
/// against a real paid-tier account).
///
/// Instagram has no Connect action of its own even though it's "launched"
/// here — there is no separate Instagram OAuth handshake; an Instagram
/// Business Account is discovered as a child of a connected Facebook Page
/// (see `FacebookOAuthProvider::listPages()` on the backend), so this only
/// gates whether the placeholder Instagram card shows a real action (the
/// "managed via Facebook" explanation) instead of "Coming soon", and
/// whether `isBetaLaunchPublishingTarget`/`...ForDiscoveryMode` below treat
/// its discovered pages as selectable.
bool isBetaLaunchPlatform(String platform) {
  switch (platform) {
    case 'facebook':
    case 'telegram':
    case 'instagram':
      return true;
    default:
      return false;
  }
}

/// The closed beta boundary is more specific than the provider allow-list:
/// Facebook can return Instagram/WhatsApp children and Telegram can return
/// other chat-like resources. A Facebook Page, a Telegram Channel, and (as
/// of 2026-08) a linked Instagram Business Account are the valid publishing
/// destinations in this release.
///
/// Keep this as a shared pure predicate so a stale saved selection cannot
/// become publishable merely because it is rendered by a different screen.
bool isBetaLaunchPublishingTarget({
  required String platform,
  required String pageKind,
}) {
  return (platform == 'facebook' && pageKind == 'page') ||
      (platform == 'telegram' && pageKind == 'channel') ||
      (platform == 'instagram' && pageKind == 'instagram_business');
}

/// [AccountPagesPanel] owns pages rather than its parent [AccountEntity].
/// The launch account flow has one durable discovery-mode mapping: Facebook
/// (and, discovered in the same sync call, Instagram) is auto-discovered and
/// Telegram channels are manually added. Treat unknown modes as ineligible
/// so selection fails closed.
bool isBetaLaunchPublishingTargetForDiscoveryMode({
  required String discoveryMode,
  required String pageKind,
}) {
  switch (discoveryMode) {
    case 'auto':
      return isBetaLaunchPublishingTarget(
            platform: 'facebook',
            pageKind: pageKind,
          ) ||
          isBetaLaunchPublishingTarget(
            platform: 'instagram',
            pageKind: pageKind,
          );
    case 'manual':
      return isBetaLaunchPublishingTarget(
        platform: 'telegram',
        pageKind: pageKind,
      );
    default:
      return false;
  }
}
