class SocialPageResponseDtoV1 {
  const SocialPageResponseDtoV1({
    required this.id,
    required this.socialAccountId,
    required this.pageId,
    this.kind = 'page',
    this.name,
    this.username,
    this.pictureUrl,
    this.canPublish = true,
    this.isSelected = false,
    this.status = 'valid',
    this.memberCount,
    this.lastSyncedAt,
    this.lastVerifiedAt,
  });

  final String id;
  final String socialAccountId;
  final String pageId;
  final String kind;
  final String? name;
  final String? username;
  final String? pictureUrl;
  final bool canPublish;
  final bool isSelected;
  final String status;
  final int? memberCount;
  final DateTime? lastSyncedAt;
  final DateTime? lastVerifiedAt;

  factory SocialPageResponseDtoV1.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>?;
    final memberCount = metadata?['member_count'];

    return SocialPageResponseDtoV1(
      id: (json['id'] ?? '').toString(),
      socialAccountId: (json['social_account_id'] ?? '').toString(),
      pageId: (json['page_id'] ?? '').toString(),
      kind: (json['kind'] ?? 'page') as String,
      name: json['name'] as String?,
      username: json['username'] as String?,
      pictureUrl: json['picture_url'] as String?,
      canPublish: (json['can_publish'] ?? true) as bool,
      isSelected: (json['is_selected'] ?? false) as bool,
      status: (json['status'] ?? 'valid') as String,
      memberCount: memberCount is int
          ? memberCount
          : int.tryParse(memberCount?.toString() ?? ''),
      lastSyncedAt: json['last_synced_at'] == null
          ? null
          : DateTime.tryParse(json['last_synced_at'].toString()),
      lastVerifiedAt: json['last_verified_at'] == null
          ? null
          : DateTime.tryParse(json['last_verified_at'].toString()),
    );
  }
}

class AddPageRequestDtoV1 {
  const AddPageRequestDtoV1({required this.identifier});

  final String identifier;

  Map<String, dynamic> toJson() => <String, dynamic>{'identifier': identifier};
}

class SelectPagesRequestDtoV1 {
  const SelectPagesRequestDtoV1({required this.pageIds});

  final List<String> pageIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'page_ids': pageIds.map(int.parse).toList(growable: false),
  };
}

class ConnectTelegramBotRequestDtoV1 {
  const ConnectTelegramBotRequestDtoV1({required this.botToken});

  final String botToken;

  Map<String, dynamic> toJson() => <String, dynamic>{'bot_token': botToken};
}
