import '../../../../core/base/base_entity.dart';

/// Recognized [status] values, matching the Laravel `SocialPage.status`
/// column exactly.
abstract final class SocialPageStatus {
  static const String valid = 'valid';
  static const String needsReauth = 'needs_reauth';
  static const String invalid = 'invalid';
}

class SocialPageEntity extends BaseEntity {
  const SocialPageEntity({
    required this.id,
    required this.socialAccountId,
    required this.pageId,
    this.kind = 'page',
    required this.name,
    this.username,
    this.pictureUrl,
    this.canPublish = true,
    this.isSelected = false,
    this.status = SocialPageStatus.valid,
    this.memberCount,
    this.lastSyncedAt,
    this.lastVerifiedAt,
  });

  @override
  final String id;
  final String socialAccountId;
  final String pageId;
  final String kind;
  final String name;
  final String? username;
  final String? pictureUrl;
  final bool canPublish;
  final bool isSelected;
  final String status;

  /// Real subscriber/member count — only ever populated for providers with a
  /// cheap real API for it (Telegram's `getChatMemberCount`). Null means "not
  /// available", and must be rendered as such, never as 0.
  final int? memberCount;
  final DateTime? lastSyncedAt;
  final DateTime? lastVerifiedAt;

  bool get isUsable => canPublish && status == SocialPageStatus.valid;

  SocialPageEntity copyWith({
    String? id,
    String? socialAccountId,
    String? pageId,
    String? kind,
    String? name,
    String? username,
    String? pictureUrl,
    bool? canPublish,
    bool? isSelected,
    String? status,
    int? memberCount,
    DateTime? lastSyncedAt,
    DateTime? lastVerifiedAt,
  }) {
    return SocialPageEntity(
      id: id ?? this.id,
      socialAccountId: socialAccountId ?? this.socialAccountId,
      pageId: pageId ?? this.pageId,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      username: username ?? this.username,
      pictureUrl: pictureUrl ?? this.pictureUrl,
      canPublish: canPublish ?? this.canPublish,
      isSelected: isSelected ?? this.isSelected,
      status: status ?? this.status,
      memberCount: memberCount ?? this.memberCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
    );
  }
}
