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

/// CTO audit P0-5: `instagram`/`linkedin`/`twitter` (X) are wired to the
/// backend's `GenericOAuthProvider`, which fakes a successful connect/publish
/// with zero real HTTP calls — connecting them here previously looked
/// identical to a real Facebook/Telegram connection. Until each has a real
/// provider implementation (Sprint 4 of the remediation plan), the Connect
/// UI must not offer them as if they worked.
///
/// This mirrors `SocialOAuthManager::provider()` on the backend by hand; the
/// 30-day backlog item is to replace this with a live capability check
/// against `GET /system-settings/oauth-providers`'s `is_mock_integration`
/// field instead of duplicating the list client-side.
bool isMockBackedPlatform(String platform) {
  switch (platform) {
    case 'instagram':
    case 'linkedin':
    case 'twitter':
    case 'x':
      return true;
    default:
      return false;
  }
}

/// Facebook and Telegram are the only two platforms the CTO audit approved
/// for a closed beta launch; everything else stays disabled in the primary
/// Connect UI even if a real provider partially exists (e.g. WhatsApp's
/// discovery works but `publishPost` isn't implemented yet).
bool isBetaLaunchPlatform(String platform) {
  switch (platform) {
    case 'facebook':
    case 'telegram':
      return true;
    default:
      return false;
  }
}

/// The closed beta boundary is more specific than the provider allow-list:
/// Facebook can return Instagram/WhatsApp children and Telegram can return
/// other chat-like resources. Only a Facebook Page and a Telegram Channel
/// are valid publishing destinations in this release.
///
/// Keep this as a shared pure predicate so a stale saved selection cannot
/// become publishable merely because it is rendered by a different screen.
bool isBetaLaunchPublishingTarget({
  required String platform,
  required String pageKind,
}) {
  return (platform == 'facebook' && pageKind == 'page') ||
      (platform == 'telegram' && pageKind == 'channel');
}

/// [AccountPagesPanel] owns pages rather than its parent [AccountEntity].
/// The launch account flow has one durable discovery-mode mapping: Facebook
/// is auto-discovered and Telegram channels are manually added. Treat unknown
/// modes as ineligible so selection fails closed.
bool isBetaLaunchPublishingTargetForDiscoveryMode({
  required String discoveryMode,
  required String pageKind,
}) {
  switch (discoveryMode) {
    case 'auto':
      return isBetaLaunchPublishingTarget(
        platform: 'facebook',
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
