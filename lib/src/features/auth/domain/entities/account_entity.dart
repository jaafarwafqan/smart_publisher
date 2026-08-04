import '../../../../core/base/base_entity.dart';
import 'social_page_entity.dart';

/// Recognized [status] values, matching the Laravel `SocialAccount.status`
/// enum exactly, plus `disconnected` for a platform that has never been
/// linked at all (the server never returns a row for those).
abstract final class AccountStatus {
  static const String connected = 'connected';
  static const String expired = 'expired';
  static const String revoked = 'revoked';
  static const String failed = 'failed';
  static const String pending = 'pending';
  static const String disconnected = 'disconnected';
}

class AccountEntity extends BaseEntity {
  const AccountEntity({
    required this.id,
    required this.name,
    required this.platform,
    this.remoteId,
    this.avatarUrl,
    this.status = AccountStatus.disconnected,
    this.hasRefreshToken = false,
    this.permissions = const <String>[],
    this.discoveryMode = 'manual',
    this.pages = const <SocialPageEntity>[],
    this.metadata = const <String, dynamic>{},
    this.tokenExpiresAt,
    this.lastSyncedAt,
    this.lastPublishedAt,
  });

  @override
  final String id;
  final String name;
  final String platform;

  /// The real backend `SocialAccount.id`, independent of [id] (which is a
  /// stable local key used for UI purposes even before a platform has ever
  /// been synced remotely). Null until the account has been linked/fetched
  /// from the server at least once.
  final String? remoteId;
  final String? avatarUrl;
  final String status;
  final bool hasRefreshToken;
  final List<String> permissions;

  /// `auto` (Facebook/Instagram-style — pages discoverable via a real list
  /// API) or `manual` (Telegram/WhatsApp-style — a channel/page must be added
  /// by identifier and verified). Drives which action ("Sync" vs "Add
  /// Channel") the accounts screen shows.
  final String discoveryMode;

  /// The Pages/Channels/Business Accounts under this connection. Populated
  /// inline by `AccountRepository.getAccounts()` so both the accounts screen
  /// and the composer have them immediately without a second round trip.
  final List<SocialPageEntity> pages;

  /// Raw backend `SocialAccount.metadata` — currently only used to check
  /// whether a WhatsApp connection has captured its Meta Business ID yet.
  final Map<String, dynamic> metadata;

  final DateTime? tokenExpiresAt;
  final DateTime? lastSyncedAt;
  final DateTime? lastPublishedAt;

  /// Derived, never stored directly, so it can never drift from [status].
  bool get isConnected => status == AccountStatus.connected;

  /// WhatsApp-specific: whether the one-time Meta Business ID has been
  /// captured yet — without it, `listPages()` has nothing to discover.
  bool get hasWhatsAppBusinessId =>
      (metadata['business_id'] as String?)?.isNotEmpty ?? false;

  AccountEntity copyWith({
    String? id,
    String? name,
    String? platform,
    String? remoteId,
    String? avatarUrl,
    String? status,
    bool? hasRefreshToken,
    List<String>? permissions,
    String? discoveryMode,
    List<SocialPageEntity>? pages,
    Map<String, dynamic>? metadata,
    DateTime? tokenExpiresAt,
    DateTime? lastSyncedAt,
    DateTime? lastPublishedAt,
  }) {
    return AccountEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      remoteId: remoteId ?? this.remoteId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      hasRefreshToken: hasRefreshToken ?? this.hasRefreshToken,
      permissions: permissions ?? this.permissions,
      discoveryMode: discoveryMode ?? this.discoveryMode,
      pages: pages ?? this.pages,
      metadata: metadata ?? this.metadata,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastPublishedAt: lastPublishedAt ?? this.lastPublishedAt,
    );
  }
}
